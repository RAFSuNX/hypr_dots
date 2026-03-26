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

# ── Get CPU Frequency ──────────────────────────────────────────────────────

get_cpu_freq() {
    local freq=0

    # Get average frequency from all cores (in MHz)
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
        freq=$(awk '{sum+=$1; count++} END {if(count>0) print int(sum/count/1000); else print "0"}' \
               /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null)
    else
        # Fallback to cpuinfo
        freq=$(grep "cpu MHz" /proc/cpuinfo | awk '{sum+=$4; count++} END {if(count>0) print int(sum/count); else print "0"}')
    fi

    echo "${freq}"
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
    local freq

    usage=$(get_cpu_usage)
    temp=$(get_cpu_temp)
    freq=$(get_cpu_freq)

    # Cap at 99
    [ "$usage" -gt 99 ] && usage=99
    [ "$temp" -gt 99 ] && temp=99

    # Convert MHz to GHz for display
    local freq_ghz=$(awk -v f="$freq" 'BEGIN {printf "%.2f", f/1000}')

    # Output JSON with tooltip
    printf '{"text":"CPU %2d%% %2d°C","tooltip":"CPU Usage: %d%%\\nFrequency: %s GHz\\nTemperature: %d°C"}' \
           "$usage" "$temp" "$usage" "$freq_ghz" "$temp"
}

main "$@"
