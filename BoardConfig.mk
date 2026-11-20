#
# SPDX-License-Identifier: Apache-2.0
#
# Recovery tree for OPPO F11 (CPH1911, MT6771). AERA Recovery (aera-16.0).
# Ported from the android-12.1 OrangeFox/TWRP tree (credits: see README).
# Decryption is OFF on purpose: the first goal is only to boot.
#

DEVICE_PATH := device/oppo/CPH1911

# Build hacks needed by recovery-only trees
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_PLUGIN_VALIDATION := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a73
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a53


# Assert
TARGET_OTA_ASSERT_DEVICE := CPH1911

# Bootloader / platform
TARGET_BOOTLOADER_BOARD_NAME := mt6771
TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := mt6771
TARGET_BOARD_PLATFORM_GPU := Mali-G72 MP3

# Kernel: prebuilt gzip kernel with appended dtb (4.14), boot header v2
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_INCLUDE_RECOVERY_DTBO := true

BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x14f88000
BOARD_KERNEL_TAGS_OFFSET := 0x13f88000
BOARD_SECOND_OFFSET := 0xbff88000
BOARD_DTB_OFFSET := 0x13f88000
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --second_offset $(BOARD_SECOND_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)

# Legacy NON-A/B device with a separate recovery partition. Declared explicitly (same as the marie tree):
# the v3 ramdisk contained update_engine_sideload, which AERA only adds when AB_OTA_UPDATER is true.
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false

# AERA's recovery binary links against the boot control client even on A-only
# devices; without these the ramdisk is missing libboot_control_client.so and
# the recovery fails to start with "library not found".
TARGET_RECOVERY_DEVICE_MODULES += \
    libboot_control_client

TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libboot_control_client.so

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := false
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_ROOT_EXTRA_FOLDERS := metadata my_product my_heytap my_company my_preload my_stock my_carrier my_region my_engineering my_manifest

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
RECOVERY_SDCARD_ON_DATA := true
AERA_SKIP_ADDITIONAL_FSTAB := true
BOARD_USES_MTP := true

# AVB
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA2048
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# OS version / patch level. No decryption here, so spoofing the patch level is harmless.
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16
# The boot header's os_version comes from PLATFORM_VERSION_LAST_STABLE; 16 matches this
# recovery (the v4 image used 12.0.0 to mirror stock, v5 builds advertise 16.0.0).
# Do NOT use BOARD_RECOVERY_MKBOOTIMG_ARGS here: when it is set AOSP stops using BOARD_MKBOOTIMG_ARGS for the
# recovery image, which silently dropped header v2, the ramdisk/tags offsets and the dtb/dtbo in the v4 build.
PLATFORM_VERSION_LAST_STABLE := 16

# Reference-tree flags (lighthouse/infiniti) that apply here
AERA_FORCE_PREBUILT_KERNEL := 1
AERA_OPTIONS_LIST_NUM := 6
# MediaTek: the health-service battery path is broken on MTK (AERA build notes), use the legacy sysfs path
TW_USE_LEGACY_BATTERY_SERVICES := true

# Decryption: OFF (boot-only bring-up). Both flags must stay UNSET: any non-empty
# value (including "false") is copied into TW_INCLUDE_CRYPTO by aera_config.mk and
# Android.mk's `ifneq ($(TW_INCLUDE_CRYPTO),)` then still pulls keystore2,
# vold_prepare_subdirs and fscryptpolicyget into the build. Unset = fully off.
# AERA_EXCLUDE_NANO_EDITOR also lives in vendorsetup.sh (the vendor packaging
# script reads it from the environment, not from here).

# UI / hardware (1080x2340 LCD, waterdrop notch, fbdev)
AERA_SCREEN_H := 2340
AERA_STATUS_H := 100
TARGET_SCREEN_DENSITY := 420
AERA_THEME := portrait_hdpi
AERA_EXTRA_LANGUAGES := false
AERA_FRAMERATE := 60
AERA_SCREEN_BLANK_ON_BOOT := true
AERA_INPUT_BLACKLIST := "hbtp_vm"
AERA_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
AERA_MAX_BRIGHTNESS := 2047
AERA_DEFAULT_BRIGHTNESS := 800
AERA_EXCLUDE_DEFAULT_USB_INIT := true
AERA_UI_ADAPTIVE_RESOLUTION := true
AERA_EXCLUDE_APEX := true

# Boot mode. twrpfastboot=1 is only for `fastboot boot` testing, never for flashing:
#   make ... F11_RAMBOOT_TEST=1
AERA_NO_FASTBOOT_BOOT := true
ifeq ($(F11_RAMBOOT_TEST),1)
    BOARD_KERNEL_CMDLINE += twrpfastboot=1
endif

# Tools
AERA_USE_TOOLBOX := true
AERA_INCLUDE_RESETPROP := true
TARGET_USES_MKE2FS := true

# XZ-compress the recovery runtime inside the ramdisk (wiki + infiniti/instantnoodlep:
# this is a BoardConfig.mk make variable, NOT a vendorsetup.sh export — compression.mk
# checks `ifeq ($(AERA_USE_EXTREME_COMPRESSION),1)`). Early init unpacks it in RAM;
# v5 run 43955625101 shipped it: ramdisk 3614 files -> 712 + aera-runtime.tar.xz.
AERA_USE_EXTREME_COMPRESSION := 1

# Logging
TARGET_USES_LOGD := true

# MTK build properties (ro.hardware etc.), like the selene tree
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
