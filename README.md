# AERA Recovery tree: OPPO F11 (CPH1911, MT6771), branch `aera-16.0`

Bring-up branch copied from `android-12.1` (which is left untouched).
**Status: untested. Goal is only to boot. Decryption is OFF.**

What changed versus `android-12.1`:
- AERA conventions (`AERA_*` variables, `aera_CPH1911.mk`, AERA-style `vendorsetup.sh`).
- Crypto/TEE/keymaster/gatekeeper services, `tee.rc` and all stock libs/blobs removed (they clash with Android 16 libs). Touch firmware under `recovery/root/vendor/firmware/tp` is kept.
- Legacy non-A/B layout kept: separate `recovery` partition, no dynamic partitions.
- `prebuilt/kernel` renamed to `prebuilt/Image.gz-dtb` (gzip kernel + appended dtb, 4.14).
- SELinux permissive on the kernel cmdline for first boot.
- `.github/workflows/build.yml` builds on every push.

Local build:
```bash
repo init -u https://github.com/AERA-Recovery/android_manifest.git -b aera-16.0 --depth=1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
git clone -b aera-16.0 https://github.com/ILYESwsa/pbrp_device_oppo_f11 device/oppo/CPH1911
export AERA_BUILD_DEVICE=CPH1911
source build/envsetup.sh
lunch twrp_CPH1911-bp2a-eng
mka adbd recoveryimage
```
Add `F11_RAMBOOT_TEST=1` only for `fastboot boot` tests, never for flashing.

Credits: Kareem Ebrahem (@mrx7014), SeifHecker2099, Seif Hamoud, Omar (original F11/CPH1989 trees); AERA Recovery, OrangeFox and TWRP teams; the everpal AERA tree used as the AERA reference.
