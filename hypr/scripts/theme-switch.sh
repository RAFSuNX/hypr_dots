#!/usr/bin/env bash
# ============================================================================
# Theme Switcher - Wallpaper-Based Material You Theming
# ============================================================================
# Purpose: Set wallpaper and auto-generate themed configs for all components
# Usage: ./theme-switch.sh <wallpaper-path>
# ============================================================================

set -euo pipefail

# ============================================================================
# Constants
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${HOME}/.config"
readonly WALLS_DIR="${CONFIG_DIR}/walls"

# ============================================================================
# Functions
# ============================================================================

log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $*"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $*"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $*"
}

check_dependencies() {
    local deps=("awww" "matugen" "hyprctl" "pkill" "pgrep")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Please install them and try again"
        exit 1
    fi
}

start_swww_daemon() {
    if ! awww query &>/dev/null; then
        log_info "Starting awww daemon..."
        awww-daemon &
        for _ in {1..20}; do
            if awww query &>/dev/null; then
                break
            fi
            sleep 0.1
        done
    fi
}

set_wallpaper() {
    local wallpaper="$1"

    log_info "Setting wallpaper: $(basename "$wallpaper")"

    awww img "$wallpaper" \
        --transition-type wipe \
        --transition-duration 2 \
        --transition-fps 60 \
        --transition-angle 30

    log_success "Wallpaper set"
}

generate_themes() {
    local wallpaper="$1"

    log_info "Extracting colors from wallpaper..."

    # Extract most vibrant color from wallpaper (awk tracks best internally — no SIGPIPE)
    local hex
    hex=$(magick "$wallpaper" -resize 50x50\! txt:- 2>/dev/null | awk '
        NR>1 {
            match($0, /#([0-9A-Fa-f]{6})/, arr)
            h = arr[1]
            r = strtonum("0x" substr(h,1,2)) / 255
            g = strtonum("0x" substr(h,3,2)) / 255
            b = strtonum("0x" substr(h,5,2)) / 255
            mx = (r>g?r:g); mx = (mx>b?mx:b)
            mn = (r<g?r:g); mn = (mn<b?mn:b)
            sat = (mx>0) ? (mx-mn)/mx : 0
            if (sat > 0.25 && sat > best_sat) { best_sat = sat; best_hex = h }
        }
        END { if (best_hex != "") print best_hex }')

    # Fallback: average color
    if [ -z "$hex" ]; then
        hex=$(magick "$wallpaper" -resize 1x1\! -format "%[hex:u]" info:- 2>/dev/null)
    fi

    if [ -z "$hex" ]; then
        log_error "Failed to extract color from wallpaper"
        exit 1
    fi

    log_info "Source color: #$hex"

    matugen color hex "#$hex" \
        --mode dark \
        --type scheme-tonal-spot \
        --config "${CONFIG_DIR}/matugen/config.toml"

    log_success "Theme configs generated"
}

reload_apps() {
    log_info "Reloading applications..."

    # Reload Hyprland (picks up new theme.lua)
    hyprctl reload

    # Restart waybar with explicit config paths
    local wpids; wpids=$(pgrep waybar)
    [ -n "$wpids" ] && kill -9 $wpids 2>/dev/null || true
    sleep 0.5
    waybar \
        --config "${CONFIG_DIR}/waybar/config.jsonc" \
        --style "${CONFIG_DIR}/waybar/style.css" \
        &>/dev/null &
    disown

    # Restart swaync
    local spids; spids=$(pgrep swaync)
    [ -n "$spids" ] && kill -9 $spids 2>/dev/null || true
    sleep 0.2
    swaync &>/dev/null &
    disown

    # Reload kitty colors in all running instances via remote control
    local kitty_colors; kitty_colors=$(mktemp /tmp/kitty-colors-XXXXXX.conf)
    grep -E "^(foreground|background |selection_|cursor|url_color|active_tab_|inactive_tab_|color[0-9]+)" \
        "${CONFIG_DIR}/kitty/theme.conf" > "$kitty_colors"
    for socket in /tmp/kitty-*; do
        kitty @ --to "unix://${socket}" set-colors --all "$kitty_colors" 2>/dev/null || true
    done
    rm -f "$kitty_colors"

    log_success "Applications reloaded cleanly"
}

save_current_wallpaper() {
    local wallpaper="$1"
    echo "$wallpaper" > "${CONFIG_DIR}/.current_wallpaper"
}

pick_random_wallpaper() {
    local current_wall=""
    local wall_file="${CONFIG_DIR}/.current_wallpaper"

    if [ -f "$wall_file" ]; then
        current_wall="$(cat "$wall_file")"
    fi

    # Find all wallpapers, exclude the current one, and pick a random one
    find "${WALLS_DIR}" -maxdepth 1 -type f ! -path "$current_wall" | shuf -n 1
}

# ============================================================================
# Main
# ============================================================================

main() {
    log_info "Hyprland Theme Switcher"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check dependencies
    check_dependencies

    # Get wallpaper path
    local wallpaper="${1:-}"

    # If no wallpaper specified, choose a random wallpaper from the walls folder.
    if [ -z "$wallpaper" ]; then
        if [ -d "${WALLS_DIR}" ]; then
            wallpaper="$(pick_random_wallpaper)"
            if [ -n "$wallpaper" ]; then
                log_info "Using random wallpaper: $(basename "$wallpaper")"
            fi
        fi

        if [ -z "$wallpaper" ]; then
            if [ -f "${WALLS_DIR}/default.jpg" ]; then
                wallpaper="${WALLS_DIR}/default.jpg"
                log_info "Using default wallpaper"
            else
                log_error "Usage: $0 <wallpaper-path>"
                log_error "No wallpapers found in ${WALLS_DIR}"
                exit 1
            fi
        fi
    fi

    # Verify wallpaper exists
    if [ ! -f "$wallpaper" ]; then
        log_error "Wallpaper not found: $wallpaper"
        exit 1
    fi

    # Make path absolute
    wallpaper="$(realpath "$wallpaper")"

    # Start swww daemon if needed
    start_swww_daemon

    # Set wallpaper
    set_wallpaper "$wallpaper"

    # Generate themed configs
    generate_themes "$wallpaper"

    # Reload applications
    reload_apps

    # Save current wallpaper
    save_current_wallpaper "$wallpaper"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Theme applied successfully!"
    log_info "Wallpaper: $(basename "$wallpaper")"
}

# Run main function
main "$@"

# ============================================================================
# End of Script
# ============================================================================