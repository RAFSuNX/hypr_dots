#!/usr/bin/env bash
# ============================================================================
# CPU Status Monitor - Waybar Module
# ============================================================================
# Displays CPU usage percentage and temperature
# Output format: "CPU XX% YY°C"
# ============================================================================

set -euo pipefail

# ── Get CPU Usage ───────────────────────────────────────────────────────────

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}'
}

# ── Get CPU Temperature ─────────────────────────────────────────────────────

get_cpu_temp() {
    local temp=0

    if command -v sensors &>/dev/null; then
        # Use lm_sensors if available
        temp=$(sensors | grep -E "^(Core|Tctl|Package)" | awk '{print $3}' | \
               grep -oE '[0-9]+' | \
               awk '{sum+=$1; count++} END {if(count>0) print int(sum/count); else print "0"}')
    else
        # Fallback to /sys thermal zones
        temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | \
               awk '{sum+=$1; count++} END {if(count>0) print int(sum/count/1000); else print "0"}')
    fi

    echo "${temp}"
}

# ── Main ────────────────────────────────────────────────────────────────────

main() {
    local usage
    local temp

    usage=$(get_cpu_usage)
    temp=$(get_cpu_temp)

    echo "CPU ${usage}% ${temp}°C"
}

main "$@"
