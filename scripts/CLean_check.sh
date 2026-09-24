#!/bin/bash

echo "=== FINAL CHECK ==="

id "$SVC_NAME" 2>&1

echo "--- mounts ---"
mount | grep "$SVC_NAME" || echo "No matching mount"

echo "--- processes ---"
pgrep -u "$SVC_NAME" 2>/dev/null || echo "No matching processes"

echo "--- scripts ---"
ls /usr/local/bin/${SVC_NAME}_*.sh 2>/dev/null || echo "No cleanup/monitor scripts"

echo "--- logrotate ---"
ls "/etc/logrotate.d/$SVC_NAME" 2>/dev/null || echo "No logrotate config"

echo "--- logs ---"
ls -ld "/var/log/$SVC_NAME" 2>/dev/null || echo "No log directory"

echo "--- tmpfs directory ---"
ls -ld "/mnt/${SVC_NAME}_tmp" 2>/dev/null || echo "No tmpfs directory"
