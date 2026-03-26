#!/usr/bin/env bash
# ============================================================================
# Audio & Bluetooth Manager - Rofi Device Selector
# ============================================================================
# Material You themed audio and bluetooth manager for Waybar
# ============================================================================

set -euo pipefail

# Icons (Simple ASCII/Unicode)
ICON_ACTIVE="●"
ICON_CONNECTED="◆"

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

        # Mark active device
        active = (device_id == current_id) ? "  ●" : "   "

        printf "%s%s\n", device_name, active
    }'
}

# Set audio output device
set_audio_device() {
    local selected=$1

    # Extract device name from selection (remove active marker)
    local device_name
    device_name=$(echo "$selected" | sed -E 's/ +●$//' | xargs)

    # Get device ID by name
    local device_id
    device_id=$(wpctl status | grep -F "$device_name" | grep -oE '^[[:space:]]*[0-9]+' | xargs)

    if [ -n "$device_id" ]; then
        wpctl set-default "$device_id" && \
            notify-send "Audio Output" "Switched to: $device_name" || \
            notify-send "Audio Error" "Failed to switch device"
    fi
}

# ============================================================================
# Bluetooth Functions
# ============================================================================

# Check if bluetoothctl is available
check_bluetooth() {
    command -v bluetoothctl &> /dev/null
}

# Get paired Bluetooth devices
get_bluetooth_devices() {
    if ! check_bluetooth; then
        return
    fi

    bluetoothctl devices Paired | while read -r _ mac name; do
        local connected=""
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            connected="  $ICON_CONNECTED"
        else
            connected="    "
        fi
        echo "$name$connected"
    done
}

# Scan for Bluetooth devices
scan_bluetooth() {
    notify-send "Bluetooth" "Scanning for devices..."

    # Start scan in background
    (
        bluetoothctl scan on &
        local scan_pid=$!
        sleep 8
        kill $scan_pid 2>/dev/null || true
    ) &

    sleep 8

    # Get all discovered devices (both paired and unpaired)
    local devices
    devices=$(bluetoothctl devices | awk '{$1=""; $2=""; print substr($0,3)}' | sort -u)

    if [ -z "$devices" ]; then
        notify-send "Bluetooth" "No devices found"
        return
    fi

    # Show devices in rofi
    local selected
    selected=$(echo "$devices" | rofi -dmenu -i -p "Select Device to Pair/Connect")

    if [ -z "$selected" ]; then
        return
    fi

    # Get MAC address
    local mac
    mac=$(bluetoothctl devices | grep -F "$selected" | awk '{print $2}' | head -1)

    if [ -z "$mac" ]; then
        notify-send "Bluetooth Error" "Device not found"
        return
    fi

    # Check if already paired
    if bluetoothctl info "$mac" | grep -q "Paired: yes"; then
        # Just connect
        bluetoothctl connect "$mac" && \
            notify-send "Bluetooth" "Connected to $selected" || \
            notify-send "Bluetooth Error" "Failed to connect to $selected"
    else
        # Pair and connect
        bluetoothctl pair "$mac" && \
        bluetoothctl trust "$mac" && \
        bluetoothctl connect "$mac" && \
            notify-send "Bluetooth" "Paired and connected to $selected" || \
            notify-send "Bluetooth Error" "Failed to pair with $selected"
    fi
}

# Toggle Bluetooth device connection
toggle_bluetooth_device() {
    local selected=$1

    # Remove connection marker
    local device_name
    device_name=$(echo "$selected" | sed -E 's/ +◆$//' | xargs)

    # Get device MAC address
    local mac
    mac=$(bluetoothctl devices Paired | grep -F "$device_name" | awk '{print $2}')

    if [ -z "$mac" ]; then
        notify-send "Bluetooth Error" "Device not found"
        return
    fi

    # Check if connected
    if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        # Disconnect
        echo "disconnect $mac" | bluetoothctl && \
            notify-send "Bluetooth" "Disconnected from $device_name" || \
            notify-send "Bluetooth Error" "Failed to disconnect"
    else
        # Connect
        echo "connect $mac" | bluetoothctl && \
            notify-send "Bluetooth" "Connected to $device_name" || \
            notify-send "Bluetooth Error" "Failed to connect"
    fi
}

# Main menu
main() {
    local current_id
    current_id=$(get_current_sink_id)

    # Build menu options
    local menu=""

    # Audio devices section
    menu+=$(get_audio_devices "$current_id")
    menu+="\n────────────────────────────────────────────────────────────────────────\n"
    menu+="Audio Settings"

    # Bluetooth section (if available)
    if check_bluetooth; then
        menu+="\n────────────────────────────────────────────────────────────────────────\n"

        # Add paired devices
        local bt_devices
        bt_devices=$(get_bluetooth_devices)
        if [ -n "$bt_devices" ]; then
            menu+="$bt_devices\n"
        fi

        # Bluetooth actions
        menu+="Scan Bluetooth Devices\n"
        menu+="Bluetooth Settings"
    fi

    # Show rofi menu
    local selected
    selected=$(echo -e "$menu" | rofi -dmenu -i -p "Audio & Bluetooth")

    # Handle selection
    if [ -z "$selected" ]; then
        exit 0
    elif [[ "$selected" == "Audio Settings" ]]; then
        pavucontrol &
    elif [[ "$selected" == "Scan Bluetooth Devices" ]]; then
        scan_bluetooth
    elif [[ "$selected" == "Bluetooth Settings" ]]; then
        blueman-manager &
    elif [[ "$selected" == *"$ICON_CONNECTED"* ]] || bluetoothctl devices Paired | grep -qF "$(echo "$selected" | xargs)"; then
        # Bluetooth device selected
        toggle_bluetooth_device "$selected"
    else
        # Audio device selected
        set_audio_device "$selected"
    fi
}

main "$@"
