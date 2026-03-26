#!/usr/bin/env bash
# ============================================================================
# Audio Manager - Rofi Audio Device Selector
# ============================================================================
# Material You themed audio output switcher for Waybar
# ============================================================================

set -euo pipefail

# Icons (Simple ASCII/Unicode)
ICON_ACTIVE="●"
ICON_SPEAKER="🔊"
ICON_HEADPHONE="🎧"
ICON_HDMI="📺"
ICON_SETTINGS="⚙"

# Get current default sink ID
get_current_sink_id() {
    wpctl status | awk '/Sinks:/,/Sources:/ { if (/\*/) { match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH); exit } }'
}

# Get list of audio output devices
get_audio_devices() {
    local current_id="$1"

    wpctl status | awk -v current_id="$current_id" '
    /Sinks:/ { sinks=1; next }
    /Sources:/ { sinks=0 }
    sinks && /[0-9]+\./ {
        # Remove leading spaces and asterisk
        gsub(/^[[:space:]]*\*?[[:space:]]*/, "")

        # Extract ID (everything before the dot)
        match($0, /^[0-9]+/)
        device_id = substr($0, RSTART, RLENGTH)

        # Extract name (everything after dot until bracket)
        match($0, /\. (.+) \[/, arr)
        device_name = arr[1]
        gsub(/^ +| +$/, "", device_name)  # trim

        # Determine icon
        icon = "🔊"
        if (device_name ~ /[Hh]eadphone|[Hh]eadset/) icon = "🎧"
        else if (device_name ~ /HDMI|DisplayPort/) icon = "📺"

        # Mark active device
        active = (device_id == current_id) ? "  ●" : "   "

        printf "%s   %s%s\n", icon, device_name, active
    }'
}

# Set audio output device
set_audio_device() {
    local selected=$1

    # Extract device name from selection (remove icon and active marker)
    local device_name
    device_name=$(echo "$selected" | sed -E 's/^[🔊🎧📺] +//' | sed -E 's/ +●$//' | xargs)

    # Get device ID by name
    local device_id
    device_id=$(wpctl status | grep -F "$device_name" | grep -oE '^[[:space:]]*[0-9]+' | xargs)

    if [ -n "$device_id" ]; then
        wpctl set-default "$device_id" && \
            notify-send "Audio Output" "Switched to: $device_name" || \
            notify-send "Audio Error" "Failed to switch device"
    fi
}

# Main menu
main() {
    local current_id
    current_id=$(get_current_sink_id)

    # Build menu options
    local menu=""
    menu+=$(get_audio_devices "$current_id")

    # Add settings option
    menu+="\n────────────────────────────────────────────────────────────────────────\n"
    menu+="⚙   Audio Settings"

    # Show rofi menu
    local selected
    selected=$(echo -e "$menu" | rofi -dmenu -i -p "Audio Output")

    # Handle selection
    if [ -z "$selected" ]; then
        exit 0
    elif [[ "$selected" == *"Audio Settings"* ]]; then
        pavucontrol &
    else
        set_audio_device "$selected"
    fi
}

main "$@"
