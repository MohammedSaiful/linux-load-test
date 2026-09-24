#!/bin/bash

set -u

TMPFS_DIR="/mnt/${SVC_NAME}_tmp"

disk_test() {
    echo "=== DISK TEST ==="
    echo "Filling $TMPFS_DIR"

    for i in $(seq 1 20); do
        echo "Writing file $i..."

        dd if=/dev/urandom \
           of="$TMPFS_DIR/file_${i}.dat" \
           bs=1M \
           count=10 \
           status=none

        if [ $? -ne 0 ]; then
            echo "Disk write stopped at file $i."
            break
        fi

        df -h "$TMPFS_DIR"
    done

    echo "=== DISK TEST COMPLETE ==="
}

cpu_test() {
    echo "=== CPU TEST ==="

    sudo -u "$SVC_NAME" stress-ng \
    --temp-path "$TMPFS_DIR" \
    --cpu 2 \
    --timeout 30s

    echo "=== CPU TEST COMPLETE ==="
}

mem_test() {
    echo "=== MEMORY TEST ==="

    sudo -u "$SVC_NAME" stress-ng \
	--temp-path "$TMPFS_DIR" \
        --vm 1 \
        --vm-bytes 200M \
        --timeout 30s

    echo "=== MEMORY TEST COMPLETE ==="
}

case "${1:-}" in

    --disk)
        disk_test
        ;;

    --cpu)
        cpu_test
        ;;

    --mem)
        mem_test
        ;;

    --all)
        disk_test &
        DISK_PID=$!

        cpu_test &
        CPU_PID=$!

        mem_test &
        MEM_PID=$!

        wait "$DISK_PID"
        wait "$CPU_PID"
        wait "$MEM_PID"

        echo "=== ALL TESTS COMPLETE ==="
        ;;

    *)
        echo "Usage: $0 --cpu | --mem | --disk | --all"
        exit 1
        ;;

esac
