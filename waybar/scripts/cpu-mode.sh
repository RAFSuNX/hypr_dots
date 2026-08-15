#!/usr/bin/env bash
OVERRIDE=$(python3 -c "import pickle; print(pickle.load(open('/var/run/override.pickle','rb')))" 2>/dev/null)

case "$OVERRIDE" in
    performance)
        echo '{"text":"PERF","tooltip":"CPU: performance, turbo on","class":"performance"}' ;;
    powersave)
        echo '{"text":"COOL","tooltip":"CPU: powersave, turbo off","class":"powersave"}' ;;
    *)
        echo '{"text":"AUTO","tooltip":"CPU: auto-managed","class":"auto"}' ;;
esac
