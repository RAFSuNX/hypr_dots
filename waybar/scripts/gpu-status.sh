#!/usr/bin/env bash
# ============================================================================
# GPU Status Monitor - Waybar Module
# ============================================================================
# Displays GPU usage percentage and temperature
# Supports NVIDIA, AMD, and Intel GPUs
# Output format: "GPU XX% YY°C"
# ============================================================================

set -euo pipefail

# ── NVIDIA GPU Stats ────────────────────────────────────────────────────────

get_nvidia_stats() {
    local usage
    local temp

    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
    temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1)

    echo "${usage} ${temp}"
}

# ── AMD GPU Stats ───────────────────────────────────────────────────────────

get_amd_stats() {
    local usage="0"
    local temp="0"

    # Get usage from sysfs (AMD GPUs expose this directly)
    if [[ -f /sys/class/drm/card1/device/gpu_busy_percent ]]; then
        usage=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo "0")
    elif command -v radeontop &>/dev/null; then
        # Fallback to radeontop if sysfs not available
        local gpu_data
        gpu_data=$(radeontop -d - -l 1 2>/dev/null | tail -1)
        usage=$(echo "$gpu_data" | grep -oP 'gpu \K[0-9]+' || echo "0")
    fi

    # Get temperature from sysfs
    if [[ -f /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input ]]; then
        temp=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | \
               head -1 | awk '{print int($1/1000)}')
    else
        temp=$(get_gpu_temp)
    fi

    echo "${usage} ${temp}"
}

# ── Generic GPU Temperature ─────────────────────────────────────────────────

get_gpu_temp() {
    local temp="0"

    if command -v sensors &>/dev/null; then
        temp=$(sensors | grep -i "gpu\|edge" | awk '{print $2}' | \
               grep -oE '[0-9]+' | head -1)
    else
        temp=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input 2>/dev/null | \
               head -1 | awk '{print int($1/1000)}')
    fi

    # Fallback to 0 if empty
    [[ -z "$temp" ]] && temp="0"

    echo "${temp}"
}

# ── Main ────────────────────────────────────────────────────────────────────

main() {
    local usage="0"
    local temp="0"
    local stats

    # Detect GPU type and get stats
    if command -v nvidia-smi &>/dev/null; then
        # NVIDIA GPU
        stats=$(get_nvidia_stats)
        read -r usage temp <<< "$stats"
    elif [[ -f /sys/class/drm/card1/device/gpu_busy_percent ]] || command -v radeontop &>/dev/null; then
        # AMD GPU (check for sysfs stats or radeontop)
        stats=$(get_amd_stats)
        read -r usage temp <<< "$stats"
    else
        # Fallback: try to get temperature only
        temp=$(get_gpu_temp)
    fi

    echo "GPU ${usage}% ${temp}°C"
}

main "$@"
