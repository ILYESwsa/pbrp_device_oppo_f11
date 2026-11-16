#!/bin/bash
# Reads the freshly built recovery.img and publishes header + ramdisk facts to ci-logs (hdr-<run>.txt).
set +e
IMG="$GITHUB_WORKSPACE/twrp/out/target/product/CPH1911/recovery.img"
[ -f "$IMG" ] || IMG="$GITHUB_WORKSPACE/aera/out/target/product/CPH1911/recovery.img"
[ -f "$IMG" ] || { echo "no recovery.img" > /tmp/hdr.txt; }
if [ -f "$IMG" ]; then
  rm -rf /tmp/mk /tmp/ub; git clone -q --depth 1 https://android.googlesource.com/platform/system/tools/mkbootimg /tmp/mk
  {
    echo "== recovery.img: $(stat -c %s "$IMG") bytes"
    python3 /tmp/mk/unpack_bootimg.py --boot_img "$IMG" --out /tmp/ub --format=mkbootimg | sed 's#/tmp/ub/#<ub>/#g'
    echo "== ramdisk file: $(stat -c %s /tmp/ub/ramdisk) bytes, magic $(xxd -l4 -p /tmp/ub/ramdisk)"
    if [ "$(xxd -l2 -p /tmp/ub/ramdisk)" = "1f8b" ]; then gzip -dc /tmp/ub/ramdisk > /tmp/rd.cpio; else sudo apt-get install -y lz4 >/dev/null 2>&1; lz4 -dc /tmp/ub/ramdisk > /tmp/rd.cpio; fi
    echo "== unpacked: $(stat -c %s /tmp/rd.cpio) bytes, entries: $(cpio -t < /tmp/rd.cpio 2>/dev/null | wc -l)"
    echo "== A/B or optional-tool artifacts in the ramdisk (want none of the A/B ones):"
    cpio -tv < /tmp/rd.cpio 2>/dev/null | grep -E "update_engine|boot@|bootctl|strace|debuggerd|busybox|gnutar|bash|wqy|NotoSans" | awk '{print $5, $NF}'
    echo "== 25 biggest files:"
    cpio -tv < /tmp/rd.cpio 2>/dev/null | sort -k5 -n -r | head -25 | awk '{print $5, $NF}'
  } > /tmp/hdr.txt 2>&1
fi
API="https://api.github.com/repos/$GITHUB_REPOSITORY/contents/ci-logs/hdr-$GITHUB_RUN_ID.txt"
base64 -w0 /tmp/hdr.txt > /tmp/hdr.b64
python3 - > /tmp/hdrbody.json <<'PY'
import json
print(json.dumps({"message":"header audit","content":open('/tmp/hdr.b64').read(),"branch":"ci-logs"}))
PY
curl -s -o /dev/null -X PUT -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" -d @/tmp/hdrbody.json "$API"
