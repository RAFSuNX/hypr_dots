#!/usr/bin/env bash
# ============================================================================
# Power Manager - Rofi Power Menu
# ============================================================================
# Material You themed power menu for Waybar
# ============================================================================

set -euo pipefail

# Main menu
main() {
    # Build menu options
    local menu=""
    menu+="Lock Screen\n"
    menu+="Logout\n"
    menu+="Suspend\n"
    menu+="Reboot\n"
    menu+="Shutdown"

    # Show rofi menu
    local selected
    selected=$(echo -e "$menu" | rofi -dmenu -i -p "Power")

    # Handle selection
    case "$selected" in
        *"Lock"*)
            loginctl lock-session
            ;;
        *"Logout"*)
            hyprctl dispatch exit
            ;;
        *"Suspend"*)
            systemctl suspend
            ;;
        *"Reboot"*)
            local confirm
            confirm=$(echo -e "No\nYes" | rofi -dmenu -i -p "Confirm Reboot?")
            if [[ "$confirm" == "Yes" ]]; then
                systemctl reboot
            fi
            ;;
        *"Shutdown"*)
            local confirm
            confirm=$(echo -e "No\nYes" | rofi -dmenu -i -p "Confirm Shutdown?")
            if [[ "$confirm" == "Yes" ]]; then
                systemctl poweroff
            fi
            ;;
        *)
            exit 0
            ;;
    esac
}

main "$@"
