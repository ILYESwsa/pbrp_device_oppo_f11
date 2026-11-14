# AERA Recovery tree: OPPO F11 (CPH1911, MT6771), branch `aera-16.0-v3`

Adapted from the AERA reference trees (oppo/lighthouse, oneplus/infiniti) and the AERA developer wiki.
**Status: bring-up, untested. Decryption OFF.** The previous image (`aera-16.0`) bootlooped.

v3 mirrors the selene (MT6768, 4.14) AERA tree, which boots Android 16 AERA on a 4.14 MediaTek kernel:
selene-style `vendorsetup.sh`, short `recovery.fstab` (other partitions in `twrp.flags`), no stock `ueventd.rc` copies,
`system.prop` with `ro.hardware`, 64+32-bit product, API level 30. Differences are forced by the F11: legacy non-A/B
with a `recovery` partition, no dynamic partitions, crypto off.

What v2 added over `aera-16.0-slim`:
- Reference-style product: `base.mk` + `core_64_bit_only.mk` (no 32-bit userspace, smaller ramdisk).
- Reference flags: `AERA_FORCE_PREBUILT_KERNEL`, `AERA_NO_TREBLE_COMPATIBILITY_CHECK`, legacy battery path (MTK), `debuggerd`/`strace`.
- `aera_dbglog.sh`: copies dmesg and recovery.log to `/cache` every second, so a bootloop leaves evidence.
  Read after the loop, from the stock ROM: `/cache/aera_dmesg.txt`, `/cache/aera_recovery.log`, `/cache/aera_info.txt`.

Build (fresh shell, `AERA_BUILD_DEVICE` set before envsetup):
```bash
repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0 --depth=1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
git clone -b aera-16.0-v3 https://github.com/ILYESwsa/pbrp_device_oppo_f11 device/oppo/CPH1911
export AERA_BUILD_DEVICE=CPH1911
source build/envsetup.sh
lunch twrp_CPH1911-bp2a-eng
mka adbd recoveryimage
```
