#!/usr/bin/env bash
if systemctl is-active --quiet auto-cpufreq; then
    echo '{"text":"COOL","tooltip":"auto-cpufreq running: powersave on battery, performance on charger","class":"powersave"}'
else
    echo '{"text":"PERF","tooltip":"auto-cpufreq stopped: kernel runs full turbo freely","class":"performance"}'
fi
