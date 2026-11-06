#!/usr/bin/env python3
"""Shrink a built recovery.img: remove keymaster/keystore/gatekeeper and Wi-Fi files from the ramdisk,
but only files that no remaining ELF needs (so recovery's own binaries keep working).
usage: slim.py <recovery.img> <outdir>   (expects tools/mkbootimg and tools/avb to be cloned)"""
import os, re, sys, shlex, shutil, subprocess, pathlib

img = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
out.mkdir(parents=True, exist_ok=True)
W = pathlib.Path('work').resolve()
shutil.rmtree(W, ignore_errors=True); W.mkdir()
TOOLS = pathlib.Path('tools').resolve()
MKB = TOOLS / 'mkbootimg'
AVB = next(iter(sorted((TOOLS / 'avb').glob('avbtool*'))), None)
PAT = re.compile(r'(keymaster|keystore|gatekeeper|wpa_supplicant|hostapd|wificond|libwifi|wmt_|wlan|libnl)', re.I)
rep = []
def log(*a):
    s = ' '.join(str(x) for x in a); print(s, flush=True); rep.append(s)
def sh(cmd, **kw):
    r = subprocess.run(cmd, text=True, capture_output=True, **kw)
    if r.returncode != 0:
        log('FAILED:', ' '.join(map(str, cmd))[:300]); log(r.stderr[-1500:]); raise SystemExit(1)
    return r
def mb(n): return f'{n/1e6:.2f} MB'

log(f'input image: {img.name} {mb(img.stat().st_size)}')
u = sh(['python3', MKB/'unpack_bootimg.py', '--boot_img', img, '--out', W/'unpack', '--format=mkbootimg'])
args = shlex.split(u.stdout.strip())
log('mkbootimg args:', u.stdout.strip()[:600])
rd = W/'unpack'/'ramdisk'
raw = rd.read_bytes()
magic = raw[:4]
if magic[:2] == b'\x1f\x8b': dec, enc = ['gzip','-dc'], ['gzip','-9n','-c']
elif magic in (b'\x02\x21\x4c\x18', b'\x04\x22\x4d\x18'): dec, enc = ['lz4','-dc'], ['lz4','-l','-9','-c']
elif magic == b'\x28\xb5\x2f\xfd': dec, enc = ['zstd','-dc'], ['zstd','-19','-c']
elif magic[:3] == b'\xfd7z': dec, enc = ['xz','-dc'], ['xz','-9','-c','--check=crc32']
else: dec, enc = None, None
log('ramdisk compression:', magic.hex(), 'compressed size', mb(len(raw)))
cpio_in = W/'ramdisk.cpio'
if dec:
    with open(rd,'rb') as f, open(cpio_in,'wb') as o: subprocess.run(dec, stdin=f, stdout=o, check=True)
else:
    shutil.copy(rd, cpio_in)
log('uncompressed cpio:', mb(cpio_in.stat().st_size))
R = W/'rd'; R.mkdir()
with open(cpio_in,'rb') as f:
    subprocess.run(['cpio','-idm','--no-absolute-filenames','--no-preserve-owner','--quiet'], stdin=f, cwd=R, check=False)

files = [p for p in R.rglob('*') if p.is_file() or p.is_symlink()]
rel = lambda p: str(p.relative_to(R))
log(f'files in ramdisk: {len(files)}')
log('--- 40 biggest files (before)')
for p in sorted([p for p in files if not p.is_symlink()], key=lambda p: -p.stat().st_size)[:40]:
    log(f'{p.stat().st_size:>10}  {rel(p)}')
log('--- files matching keymaster/wifi patterns (before)')
hits = sorted(rel(p) for p in files if PAT.search(p.name))
for h in hits: log('  ', h)

def needed(p):
    try:
        if p.is_symlink() or p.read_bytes()[:4] != b'\x7fELF': return set()
    except Exception: return set()
    r = subprocess.run(['readelf','-d',str(p)], text=True, capture_output=True)
    return set(re.findall(r'\(NEEDED\)\s+Shared library: \[(.*?)\]', r.stdout))
NEED = {p: needed(p) for p in files}
cand = {p for p in files if PAT.search(p.name)}
kept_needed = []
changed = True
while changed:
    changed = False
    used = set()
    for p, n in NEED.items():
        if p not in cand: used |= n
    for c in sorted(cand):
        if c.name in used:
            cand.discard(c); kept_needed.append(rel(c)); changed = True
log('--- kept because a remaining binary needs them')
for k in sorted(set(kept_needed)): log('  ', k)
log('--- removing')
freed = 0
for c in sorted(cand):
    try:
        if not c.is_symlink(): freed += c.stat().st_size
        c.unlink(); log('  ', rel(c))
    except FileNotFoundError: pass
for p in list(R.rglob('*')):      # drop dangling symlinks left behind
    if p.is_symlink() and not p.exists():
        log('   dangling symlink removed:', rel(p)); p.unlink()
log(f'freed (uncompressed): {mb(freed)}')

new_cpio = W/'new.cpio'
cmd = "find . -print0 | LC_ALL=C sort -z | cpio --null -o -H newc -R 0:0 --quiet"
with open(new_cpio,'wb') as o: subprocess.run(cmd, shell=True, cwd=R, stdout=o, check=True)
new_rd = W/'ramdisk.new'
if enc:
    with open(new_cpio,'rb') as f, open(new_rd,'wb') as o: subprocess.run(enc, stdin=f, stdout=o, check=True)
else: shutil.copy(new_cpio, new_rd)
log(f'ramdisk compressed: {mb(len(raw))} -> {mb(new_rd.stat().st_size)}')

i = args.index('--ramdisk'); args[i+1] = str(new_rd)
newimg = W/'recovery-slim.img'
sh(['python3', MKB/'mkbootimg.py'] + args + ['--output', newimg])
log('repacked (no footer):', mb(newimg.stat().st_size))

alg = None
if AVB:
    info = subprocess.run(['python3', AVB, 'info_image', '--image', str(img)], text=True, capture_output=True)
    m = re.search(r'Algorithm:\s+(\S+)', info.stdout)
    if info.returncode == 0 and m: alg = m.group(1)
log('original AVB footer algorithm:', alg)
if alg:
    cmd = ['python3', AVB, 'add_hash_footer', '--image', str(newimg), '--partition_size', str(img.stat().st_size),
           '--partition_name', 'recovery', '--algorithm', alg]
    if alg != 'NONE': cmd += ['--key', str(TOOLS/'avb'/'test'/'data'/'testkey_rsa2048.pem')]
    sh(cmd)
shutil.copy(newimg, out/'recovery-slim.img')
log(f'final: {mb((out/"recovery-slim.img").stat().st_size)} (partition image size; ramdisk shrank by {mb(len(raw)-new_rd.stat().st_size)})')
(out/'report.txt').write_text('\n'.join(rep)+'\n')
