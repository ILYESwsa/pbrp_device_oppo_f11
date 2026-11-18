#!/system/bin/sh
# Save recovery diagnostics on the cache partition.
dir=/mnt/dbg
mkdir -p "$dir" || exit 1
attempt=0
while [ "$attempt" -lt 15 ]; do
    for block in /dev/block/by-name/cache /dev/block/platform/bootdevice/by-name/cache; do
        [ -b "$block" ] || continue
        mount -t ext4 -o rw,nosuid,nodev "$block" "$dir" && break 2
    done
    attempt=$((attempt + 1))
    sleep 1
done
if ! grep -q " $dir ext4 rw," /proc/mounts; then
    echo 'aera_dbglog: cache mount failed' > /dev/kmsg
    exit 1
fi

date > "$dir/aera_info.txt"
sync
i=0
while [ "$i" -lt 1800 ]; do
    if dmesg > "$dir/.aera_dmesg.tmp" 2>&1; then
        mv -f "$dir/.aera_dmesg.tmp" "$dir/aera_dmesg.txt"
    fi
    if [ -r /tmp/recovery.log ] && cat /tmp/recovery.log > "$dir/.aera_recovery.tmp"; then
        mv -f "$dir/.aera_recovery.tmp" "$dir/aera_recovery.log"
    fi
    sync
    i=$((i + 1))
    sleep 1
done
