#!/usr/bin/env bash
if systemctl is-active --quiet auto-cpufreq; then
    sudo systemctl stop auto-cpufreq
else
    sudo systemctl start auto-cpufreq
fi
