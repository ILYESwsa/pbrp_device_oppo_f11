#!/bin/bash
# Builds recovery_permissive.img from the freshly built recovery.img: ONLY the kernel cmdline changes
# (adds androidboot.selinux=permissive); kernel, ramdisk, dtb, dtbo are byte-identical. Re-signed with the AOSP test key.
set -e
IMG="$GITHUB_WORKSPACE/aera/out/target/product/CPH1911/recovery.img"
OUT="$GITHUB_WORKSPACE/variants"; mkdir -p "$OUT"
rm -rf /tmp/mk /tmp/avb /tmp/ubv
git clone -q --depth 1 https://android.googlesource.com/platform/system/tools/mkbootimg /tmp/mk
git clone -q --depth 1 https://android.googlesource.com/platform/external/avb /tmp/avb
python3 - "$IMG" "$OUT" <<'PY'
import sys, shlex, subprocess, shutil, pathlib
img, out = sys.argv[1], pathlib.Path(sys.argv[2])
u = subprocess.run(['python3','/tmp/mk/unpack_bootimg.py','--boot_img',img,'--out','/tmp/ubv','--format=mkbootimg'],capture_output=True,text=True,check=True).stdout
args = shlex.split(u.strip())
i = args.index('--cmdline'); cmd = args[i+1]
if 'androidboot.selinux=permissive' not in cmd: args[i+1] = (cmd + ' androidboot.selinux=permissive').strip()
osv = args[args.index('--os_version')+1].split('.')[0]
tmp = pathlib.Path('/tmp/perm.img')
subprocess.run(['python3','/tmp/mk/mkbootimg.py'] + args + ['--output', str(tmp)], check=True)
avb = next(pathlib.Path('/tmp/avb').glob('avbtool*'))
fp = 'OPPO/CPH1911/OP4883:11/RP1A.200720.011/1705377488980:user/release-keys'
subprocess.run(['python3',str(avb),'add_hash_footer','--image',str(tmp),'--partition_size','67108864','--partition_name','recovery',
  '--algorithm','SHA256_RSA2048','--key','/tmp/avb/test/data/testkey_rsa2048.pem','--prop','com.android.build.recovery.fingerprint:'+fp,
  '--prop','com.android.build.boot.os_version:'+osv,'--prop','com.android.build.boot.security_patch:2099-12-31'], check=True)
shutil.copy(tmp, out/'recovery_permissive.img')
print('cmdline:', args[i+1], '| size', (out/'recovery_permissive.img').stat().st_size)
PY
