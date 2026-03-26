#!/usr/bin/env bash
# ============================================================================
# Network Manager - Rofi WiFi Selector
# ============================================================================
# Material You themed network switcher for Waybar
# ============================================================================

set -euo pipefail

# Icons (Simple ASCII/Unicode)
ICON_DISCONNECTED="✕"
ICON_SIGNAL_EXCELLENT="████"
ICON_SIGNAL_GOOD="███░"
ICON_SIGNAL_OK="██░░"
ICON_SIGNAL_WEAK="█░░░"
ICON_CONNECTED="●"
ICON_SECURITY="⚿"

# Get current connection
get_current_network() {
    nmcli -t -f NAME connection show --active | head -n1
}

# Get signal strength icon
get_signal_icon() {
    local signal=$1
    if [ "$signal" -ge 80 ]; then
        echo "$ICON_SIGNAL_EXCELLENT"
    elif [ "$signal" -ge 60 ]; then
        echo "$ICON_SIGNAL_GOOD"
    elif [ "$signal" -ge 40 ]; then
        echo "$ICON_SIGNAL_OK"
    else
        echo "$ICON_SIGNAL_WEAK"
    fi
}

# Get list of WiFi networks (instant version with cached data)
get_networks() {
    local current_network="$1"

    # Use -g for terse mode (uses cached scan, no hardware scan)
    nmcli -g SSID,SIGNAL,SECURITY device wifi | awk -F: -v current="$current_network" '
    {
        ssid = $1
        signal = $2
        security = $3

        if (ssid == "") next

        # Signal icon
        if (signal >= 80) sig = "████"
        else if (signal >= 60) sig = "███░"
        else if (signal >= 40) sig = "██░░"
        else sig = "█░░░"

        # Security icon
        sec = (security != "--") ? "  ⚿" : "   "

        # Connected icon
        conn = (ssid == current) ? "  ●" : "   "

        printf "%s   %s%s%s\n", sig, ssid, sec, conn
    }'
}

# Connect to network
connect_network() {
    local selected=$1

    # Extract SSID from selection (remove signal bars, security icon, connected dot)
    local ssid
    ssid=$(echo "$selected" | sed -E 's/^[█░]+ +//' | sed -E 's/ +⚿//g' | sed -E 's/ +●//g' | xargs)

    # Check if network requires password (use cached data)
    local security
    security=$(nmcli -g SSID,SECURITY device wifi | grep "^$ssid:" | cut -d: -f2)

    if [ "$security" != "--" ]; then
        # Prompt for password using rofi
        local password
        password=$(rofi -dmenu -p "Password" -password)

        if [ -n "$password" ]; then
            nmcli device wifi connect "$ssid" password "$password" && \
                notify-send "WiFi Connected" "Connected to $ssid" || \
                notify-send "Connection Failed" "Could not connect to $ssid"
        fi
    else
        # Open network
        nmcli device wifi connect "$ssid" && \
            notify-send "WiFi Connected" "Connected to $ssid" || \
            notify-send "Connection Failed" "Could not connect to $ssid"
    fi
}

# Disconnect from current network
disconnect_network() {
    local current_network
    current_network=$(get_current_network)

    if [ -n "$current_network" ]; then
        nmcli connection down "$current_network" && \
            notify-send "WiFi Disconnected" "Disconnected from $current_network"
    fi
}

# Main menu
main() {
    local current_network
    current_network=$(get_current_network)

    # Build menu options
    local menu=""

    # Add disconnect option if connected
    if [ -n "$current_network" ]; then
        menu="✕   Disconnect from $current_network\n"
        menu+="────────────────────────────────────────────────────────────────────────\n"
    fi

    # Add available networks (pass current_network to avoid duplicate call)
    menu+=$(get_networks "$current_network")

    # Add settings option
    menu+="\n────────────────────────────────────────────────────────────────────────\n"
    menu+="⚙   Network Settings"

    # Show rofi menu
    local selected
    selected=$(echo -e "$menu" | rofi -dmenu -i -p "WiFi")

    # Handle selection
    if [ -z "$selected" ]; then
        exit 0
    elif [[ "$selected" == *"Disconnect"* ]]; then
        disconnect_network
    elif [[ "$selected" == *"Network Settings"* ]]; then
        nm-connection-editor &
    else
        connect_network "$selected"
    fi
}

main "$@"
