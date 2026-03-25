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

wait_for_layer_exit() {
    local namespace="$1"
    local attempts=20

    while [ "$attempts" -gt 0 ]; do
        if ! hyprctl layers 2>/dev/null | grep -q "namespace: ${namespace},"; then
            return 0
        fi

        sleep 0.1
        attempts=$((attempts - 1))
    done

    return 1
}

kill_pids_by_name() {
    local name="$1"
    local signal="${2:-TERM}"
    local pids

    pids="$(pgrep -x "$name" 2>/dev/null || true)"
    if [ -n "$pids" ]; then
        # shellcheck disable=SC2086
        kill "-${signal}" $pids 2>/dev/null || true
    fi
}

check_dependencies() {
    local deps=("swww" "matugen" "hyprctl")
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
        sleep 1
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

    # Restart Waybar cleanly to avoid races between old and newly spawned instances.
    log_info "Restarting waybar..."
    kill_pids_by_name "waybar"
    if ! wait_for_layer_exit "waybar"; then
        log_info "Waybar layer still present, forcing shutdown..."
        kill_pids_by_name "waybar" "KILL"
        wait_for_layer_exit "waybar" || true
    fi
    waybar &
    disown

    # Restart SwayNC cleanly for the same reason.
    log_info "Restarting swaync..."
    kill_pids_by_name "swaync"
    sleep 0.2
    swaync &
    disown

    # Reload Hyprland config
    log_info "Reloading hyprland..."
    hyprctl reload

    # Kitty auto-reloads via theme.conf include
    # Send signal to all kitty instances to reload config
    kill_pids_by_name "kitty" "USR1"

    log_success "Applications reloaded"
}

save_current_wallpaper() {
    local wallpaper="$1"
    echo "$wallpaper" > "${CONFIG_DIR}/.current_wallpaper"
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

    # If no wallpaper specified, use default or show usage
    if [ -z "$wallpaper" ]; then
        if [ -f "${CONFIG_DIR}/.current_wallpaper" ]; then
            wallpaper="$(cat "${CONFIG_DIR}/.current_wallpaper")"
            log_info "Using current wallpaper: $(basename "$wallpaper")"
        elif [ -f "${WALLS_DIR}/default.jpg" ]; then
            wallpaper="${WALLS_DIR}/default.jpg"
            log_info "Using default wallpaper"
        else
            log_error "Usage: $0 <wallpaper-path>"
            log_error "No wallpaper specified and no default found"
            exit 1
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
