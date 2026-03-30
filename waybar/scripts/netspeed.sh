#!/usr/bin/env bash
# Script: netspeed.sh
# Description: Display live network upload/download speeds for waybar

set -euo pipefail

# Find the active network interface
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)

# Fallback to first active interface if default route not found
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|docker|^[^0-9]"{print $2;getline}' | head -n1 | tr -d ' ')
fi

# Cache file for previous values
CACHE_FILE="/tmp/waybar-netspeed-${INTERFACE}"

# Read current network stats
read -r RX_BYTES TX_BYTES < <(
    awk -v iface="$INTERFACE:" '
        $1 == iface {
            print $2, $10
            exit
        }
    ' /proc/net/dev
)

# Read previous values from cache
if [ -f "$CACHE_FILE" ]; then
    read -r OLD_RX OLD_TX OLD_TIME < "$CACHE_FILE"
else
    OLD_RX=0
    OLD_TX=0
    OLD_TIME=$(date +%s)
fi

# Current time
CURRENT_TIME=$(date +%s)
TIME_DIFF=$((CURRENT_TIME - OLD_TIME))

# Avoid division by zero
if [ "$TIME_DIFF" -eq 0 ]; then
    TIME_DIFF=1
fi

# Calculate speeds in bytes per second
RX_SPEED=$(( (RX_BYTES - OLD_RX) / TIME_DIFF ))
TX_SPEED=$(( (TX_BYTES - OLD_TX) / TIME_DIFF ))

# Save current values for next iteration
echo "$RX_BYTES $TX_BYTES $CURRENT_TIME" > "$CACHE_FILE"

# Format speeds with appropriate units and fixed width
format_speed() {
    local speed=$1
    if [ "$speed" -lt 1024 ]; then
        printf "%4d B/s" "$speed"
    elif [ "$speed" -lt 1048576 ]; then
        printf "%4d KB/s" "$(( speed / 1024 ))"
    else
        printf "%4d MB/s" "$(( speed / 1048576 ))"
    fi
}

RX_FORMATTED=$(format_speed "$RX_SPEED")
TX_FORMATTED=$(format_speed "$TX_SPEED")

# Output JSON for waybar with fixed width
printf '{"text":"↓ %s ↑ %s","tooltip":"%s\\nDown: %s\\nUp: %s"}\n' \
    "$RX_FORMATTED" "$TX_FORMATTED" "$INTERFACE" "$RX_FORMATTED" "$TX_FORMATTED"
