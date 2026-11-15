#!/usr/bin/env python3
"""Build isolation images from the AERA v3 recovery.img. Kernel, dtb and dtbo are never touched.
 T3 trim_workinghdr : AERA ramdisk trimmed under ~29 MB gzip + the WORKING header (os 12.0.0, cmdline without permissive)
 T4 trim_aerahdr    : same trimmed ramdisk + AERA's own header      (T3 vs T4 isolates the header)
 T5 min_workinghdr  : Android 16 init only, tiny ramdisk + working header (does A16 init run on this kernel?)
 T2 full_workinghdr : full 40 MB ramdisk + working header           (does the size limit apply to AERA?)"""
import os, pathlib, re, shlex, shutil, subprocess, sys, zlib
IMG = pathlib.Path(sys.argv[1]).resolve(); OUT = pathlib.Path(sys.argv[2]).resolve(); OUT.mkdir(parents=True, exist_ok=True)
W = pathlib.Path('work').resolve(); shutil.rmtree(W, ignore_errors=True); W.mkdir()
TOOLS = pathlib.Path('tools').resolve(); MK = TOOLS/'mkbootimg'
AVB = sorted((TOOLS/'avb').glob('avbtool*'))[0]; KEY = TOOLS/'avb'/'test'/'data'/'testkey_rsa2048.pem'
FP = 'OPPO/CPH1911/OP4883:11/RP1A.200720.011/1705377488980:user/release-keys'
TARGET_GZ = 29_000_000
rep = []
def say(*a):
    s = ' '.join(str(x) for x in a); print(s, flush=True); rep.append(s)
def sh(cmd, **kw):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, **kw)
    if r.returncode: say('FAILED:', ' '.join(map(str, cmd))[:250]); say(r.stderr[-1200:]); sys.exit(1)
    return r
def mb(n): return f'{n/1e6:.2f} MB'
def gz(b, level=9):
    co = zlib.compressobj(level, zlib.DEFLATED, 31); return co.compress(b) + co.flush()
# ---- cpio newc helpers (round-trip tested in the earlier session)
def read_cpio(raw):
    ents = []; i = 0
    while True:
        h = raw[i:i+110]; f = lambda k: int(h[6+8*k:14+8*k], 16)
        size = f(6); nsz = f(11)
        nm = raw[i+110:i+110+nsz-1].decode(errors='replace')
        o = (i+110+nsz+3) & ~3
        ents.append([nm, bytearray(h), raw[i+110:o], raw[o:o+size]])
        i = (o+size+3) & ~3
        if nm == 'TRAILER!!!': break
    return ents
def write_cpio(ents):
    out = bytearray()
    for nm, h, nmb, body in ents:
        hh = bytearray(h); hh[6+8*6:14+8*6] = b'%08x' % len(body)
        e = bytes(hh) + nmb + body; e += b'\0' * ((-len(e)) % 4); out += e
    return bytes(out)
mode_of = lambda e: int(bytes(e[1])[14:22], 16)
isreg = lambda e: (mode_of(e) & 0o170000) == 0o100000
# ---- unpack the source image
say('source:', IMG.name, mb(IMG.stat().st_size))
args = shlex.split(sh(['python3', MK/'unpack_bootimg.py', '--boot_img', IMG, '--out', W/'u', '--format=mkbootimg']).stdout.strip())
do = zlib.decompressobj(31); raw = do.decompress((W/'u'/'ramdisk').read_bytes())
ents0 = read_cpio(raw)
say('AERA ramdisk: gz', mb(len((W/'u'/'ramdisk').read_bytes())), 'unpacked', mb(len(raw)), 'entries', len(ents0))
say('source header args:', ' '.join(a for a in args if not a.startswith('/'))[:500])
# ---- trimming
def elf_needed(body):
    p = W/'tmp.elf'; p.write_bytes(body)
    r = subprocess.run(['readelf', '-d', str(p)], capture_output=True, text=True)
    return set(re.findall(r'\(NEEDED\)\s+Shared library: \[(.*?)\]', r.stdout))
def closure(ents, roots):
    byname = {e[0]: e for e in ents}; bybase = {}
    for e in ents: bybase.setdefault(os.path.basename(e[0]), []).append(e[0])
    keep = set(); stack = [r for r in roots if r in byname]
    while stack:
        n = stack.pop()
        if n in keep: continue
        keep.add(n); e = byname[n]
        if isreg(e) and e[3][:4] == b'\x7fELF':
            for so in elf_needed(e[3]): stack += bybase.get(so, [])
        if (mode_of(e) & 0o170000) == 0o120000:
            t = e[3].decode(errors='replace')
            t = t.lstrip('/') if t.startswith('/') else os.path.normpath(os.path.join(os.path.dirname(n), t))
            if t in byname: stack.append(t)
    return keep
ROOTS = ['init','system/bin/init','system/bin/recovery','system/bin/adbd','system/bin/linker64','system/bin/sh','system/bin/toybox',
         'system/bin/toolbox','system/bin/ueventd','system/bin/logd','system/bin/servicemanager','system/bin/hwservicemanager','system/bin/vndservicemanager']
def trim(ents):
    keep = closure(ents, ROOTS)
    cands = sorted([e for e in ents if isreg(e) and e[0] not in keep and len(e[3]) > 150_000 and not e[0].startswith(('system/lib64/hw/','vendor/'))],
                   key=lambda e: -len(e[3]))
    say(f'trim: closure {len(keep)} files kept, {len(cands)} removable candidates >150 KB')
    cur = list(ents); removed = []
    for e in cands:
        if len(gz(write_cpio(cur), 6)) < TARGET_GZ: break
        cur = [x for x in cur if x is not e]; removed.append(e)
    say('trim removed', len(removed), 'files,', mb(sum(len(e[3]) for e in removed)), 'unpacked:')
    for e in removed[:30]: say(f'   {len(e[3]):>9}  {e[0]}')
    return cur
def minimal(ents):
    drop = ('system/bin/recovery','system/bin/update_engine_sideload','system/bin/7za','system/bin/aera-otaripper','system/bin/strace','system/bin/adbd','twres/','res/','sbin/')
    out = []
    for e in ents:
        if isreg(e) and e[0].startswith(drop): continue
        if e[0] == 'system/etc/init/hw/init.rc': e = [e[0], e[1], e[2], b'# min: init only\n']
        out.append(e)
    return out
# ---- assemble with the official mkbootimg + avbtool
def build(name, ents, hdr):
    cp = write_cpio(ents); g = gz(cp); rd = W/f'{name}.ramdisk'; rd.write_bytes(g)
    a = list(args); a[a.index('--ramdisk')+1] = str(rd)
    osv = a[a.index('--os_version')+1]
    if hdr == 'work':
        osv = '12.0.0'; a[a.index('--os_version')+1] = osv
        a[a.index('--cmdline')+1] = 'bootopt=64S3,32N2,64N2'
    img = W/f'{name}.img'
    sh(['python3', MK/'mkbootimg.py'] + a + ['--output', img])
    pre = img.stat().st_size
    sh(['python3', AVB, 'add_hash_footer', '--image', img, '--partition_size', '67108864', '--partition_name', 'recovery',
        '--algorithm', 'SHA256_RSA2048', '--key', KEY, '--prop', f'com.android.build.recovery.fingerprint:{FP}',
        '--prop', f'com.android.build.boot.os_version:{osv.split(".")[0]}', '--prop', 'com.android.build.boot.security_patch:2099-12-31'])
    chk = sh(['python3', MK/'unpack_bootimg.py', '--boot_img', img, '--out', W/f'chk_{name}', '--format=mkbootimg']).stdout
    m = re.search(r"--os_version (\S+)", chk); c = re.search(r"--cmdline '?([^']*)'?", chk)
    shutil.copy(img, OUT/f'recovery_{name}.img')
    say(f'{name}: file {img.stat().st_size} (content {pre}), ramdisk gz {mb(len(g))}, unpacked {mb(len(cp))}, header os={m.group(1) if m else "?"} cmdline="{c.group(1) if c else "?"}"')
trimmed = trim(ents0)
build('T3_trim_workinghdr', trimmed, 'work')
build('T4_trim_aerahdr', trimmed, 'aera')
build('T5_min_workinghdr', minimal(ents0), 'work')
build('T2_full_workinghdr', ents0, 'work')
(OUT/'report.txt').write_text('\n'.join(rep) + '\n')
