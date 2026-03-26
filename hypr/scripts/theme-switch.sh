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
    local deps=("swww" "matugen" "hyprctl" "pkill" "pgrep")
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
    if ! pgrep -x swww-daemon > /dev/null; then
        log_info "Starting swww daemon..."
        swww-daemon &
        
        # Wait up to 2 seconds for socket to be ready
        for _ in {1..20}; do
            if swww query &>/dev/null; then
                break
            fi
            sleep 0.1
        done
    fi
}

set_wallpaper() {
    local wallpaper="$1"

    log_info "Setting wallpaper: $(basename "$wallpaper")"

    swww img "$wallpaper" \
        --transition-type wipe \
        --transition-duration 2 \
        --transition-fps 60 \
        --transition-angle 30

    log_success "Wallpaper set"
}

generate_themes() {
    local wallpaper="$1"

    log_info "Extracting colors from wallpaper..."

    # Run matugen to extract colors and generate themed configs
    matugen image "$wallpaper" \
        --mode dark \
        --type scheme-tonal-spot \
        --config "${CONFIG_DIR}/matugen/config.toml"

    log_success "Theme configs generated"
}

reload_apps() {
    log_info "Reloading applications..."

    # Reload hyprland instantly
    hyprctl reload &

    # Hard restart Waybar (use -f for wrapped processes)
    (
        pkill -f waybar || true
        sleep 0.2
        pkill -9 -f waybar || true
        hyprctl dispatch exec waybar
    ) &

    # Hard restart SwayNC
    (
        pkill -f swaync || true
        sleep 0.2
        pkill -9 -f swaync || true
        hyprctl dispatch exec swaync
    ) &

    # Reload kitty terminals with remote control
    if command -v killall &> /dev/null; then
        killall -SIGUSR1 kitty 2>/dev/null || true
    else
        pkill -USR1 kitty 2>/dev/null || true
    fi &

    wait
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