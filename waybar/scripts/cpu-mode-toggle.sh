#!/usr/bin/env bash
OVERRIDE=$(python3 -c "import pickle; print(pickle.load(open('/var/run/override.pickle','rb')))" 2>/dev/null)

case "$OVERRIDE" in
    performance) sudo auto-cpufreq --force=reset ;;
    powersave)   sudo auto-cpufreq --force=performance ;;
    *)           sudo auto-cpufreq --force=powersave ;;
esac
