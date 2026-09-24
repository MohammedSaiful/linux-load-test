#!/bin/bash

set -u

SVC_NAME="bgdsvc_saiful"
TMPFS_DIR="/mnt/${SVC_NAME}_tmp"

echo "=== CLEANUP STARTED ==="

# 1. Kill processes belonging to the service account
if id "$SVC_NAME" >/dev/null 2>&1; then
    echo "[1/5] Stopping processes for $SVC_NAME..."
    sudo pkill -u "$SVC_NAME" 2>/dev/null || true
else
    echo "[1/5] Service account does not exist. Skipping process cleanup."
fi

# 2. Remove automation
echo "[2/5] Removing automation..."

if id "$SVC_NAME" >/dev/null 2>&1; then
    sudo crontab -r -u "$SVC_NAME" 2>/dev/null || true
else
    echo "      Service account already removed; skipping crontab."
fi

sudo rm -f "/etc/logrotate.d/$SVC_NAME"
sudo rm -f "/usr/local/bin/${SVC_NAME}_monitor.sh"
sudo rm -f "/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"

# 3. Unmount and remove tmpfs
echo "[3/5] Removing tmpfs..."

if mountpoint -q "$TMPFS_DIR"; then
    sudo umount "$TMPFS_DIR"
else
    echo "      tmpfs is not mounted."
fi

if [ -d "$TMPFS_DIR" ]; then
    sudo rmdir "$TMPFS_DIR" 2>/dev/null || true
fi

# 4. Remove logs
echo "[4/5] Removing logs..."
sudo rm -rf "/var/log/$SVC_NAME"

# 5. Remove service account
echo "[5/5] Removing service account..."

if id "$SVC_NAME" >/dev/null 2>&1; then
    sudo userdel -r "$SVC_NAME"
else
    echo "      Service account already removed."
fi

echo "=== CLEANUP COMPLETE ==="
