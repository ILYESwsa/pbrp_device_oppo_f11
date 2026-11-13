#!/system/bin/sh
# Bring-up helper: keep the kernel log and recovery log on /cache so they survive a bootloop.
# Read them later from the stock ROM:  /cache/aera_dmesg.txt  /cache/aera_recovery.log  /cache/aera_info.txt
mkdir -p /mnt/dbg
mount -t ext4 -o rw,nosuid,nodev /dev/block/by-name/cache /mnt/dbg 2>/dev/null || \
mount -t ext4 -o rw,nosuid,nodev /dev/block/platform/bootdevice/by-name/cache /mnt/dbg 2>/dev/null
[ -d /mnt/dbg ] || exit 0
{
  date; echo "--- getprop"; getprop 2>&1; echo "--- ls /system/bin"; ls /system/bin 2>&1
  echo "--- ls /dev/graphics /dev/dri"; ls -l /dev/graphics /dev/dri 2>&1
} > /mnt/dbg/aera_info.txt 2>&1
i=0
while [ "$i" -lt 1800 ]; do
  { date; dmesg || toybox dmesg || cat /proc/kmsg; } > /mnt/dbg/aera_dmesg.txt 2>&1
  cat /tmp/recovery.log > /mnt/dbg/aera_recovery.log 2>/dev/null
  sync
  i=$((i+1)); sleep 1
done
