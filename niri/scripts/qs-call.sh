#!/usr/bin/env bash
# qs-call.sh <target> <function> [args...]
# Calls the quickshell sidebar over IPC and starts it first if it isn't running.
# (The sidebar quits itself after ~2 min without use, which keeps idle RAM low.)
call() { qs -c sidebar ipc call "$@" >/dev/null 2>&1; }
call "$@" && exit 0
pgrep -x qs >/dev/null || setsid qs -c sidebar >/dev/null 2>&1 &
for _ in $(seq 1 80); do sleep 0.05; call "$@" && exit 0; done
exit 1
