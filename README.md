# TWRP 14.1 tree: OPPO F11 (CPH1911, MT6771), branch `android-14.1`

Port of the `android-12.1` tree (left untouched) to the official TWRP 14.1 minimal manifest
(AOSP android-14.0.0_r67). **Status: untested. Goal is only to boot. Decryption is OFF.**

Changes versus `android-12.1`:
- Stock Android 11 libs/blobs, TEE/keymaster/gatekeeper services and OrangeFox-only files removed (they clash with the newer userspace; crypto is off).
- `BoardConfig.mk` cleaned for 14.1 (no obsolete variables, no system-root flag, no SHRP/PB vars, kernel renamed `prebuilt/Image.gz-dtb`, SELinux permissive on cmdline).
- Wi-Fi leftovers removed (`init_A.rc`, WMT ueventd lines).
- `.github/workflows/build.yml` builds on every push (sync cached between runs).

Local build:
```bash
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1 --depth=1
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
git clone -b android-14.1 https://github.com/ILYESwsa/pbrp_device_oppo_f11 device/oppo/CPH1911
export ALLOW_MISSING_DEPENDENCIES=true LC_ALL=C
source build/envsetup.sh
lunch twrp_CPH1911-ap2a-eng
mka adbd recoveryimage
```
Add `F11_RAMBOOT_TEST=1` only for `fastboot boot` tests, never for flashing.

Credits: Omar, SeifHecker2099 and the original F11/CPH1989 tree authors; TWRP team.
