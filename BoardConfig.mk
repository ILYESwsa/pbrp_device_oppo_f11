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
TARGET_SUPPORTS_64_BIT_APPS := true


# Assert
TARGET_OTA_ASSERT_DEVICE := CPH1911

# Bootloader / platform
TARGET_BOOTLOADER_BOARD_NAME := mt6771
TARGET_NO_BOOTLOADER := true
TARGET_BOARD_PLATFORM := mt6771
TARGET_BOARD_PLATFORM_GPU := Mali-G72 MP3

# Kernel: prebuilt gzip kernel with appended dtb (4.14), boot header v2
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
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

# Partitions (legacy non-A/B: separate recovery partition)
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
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)

# Reference-tree flags (lighthouse/infiniti) that apply here
AERA_FORCE_PREBUILT_KERNEL := 1
AERA_NO_TREBLE_COMPATIBILITY_CHECK := 1
AERA_OPTIONS_LIST_NUM := 6
# MediaTek: the health-service battery path is broken on MTK (AERA build notes), use the legacy sysfs path
TW_USE_LEGACY_BATTERY_SERVICES := true

# Debug tools in the recovery (same as the reference trees)
TARGET_RECOVERY_DEVICE_MODULES += debuggerd
TARGET_RECOVERY_DEVICE_MODULES += strace
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace

# Decryption: OFF (boot-only bring-up)
AERA_INCLUDE_CRYPTO := false
AERA_INCLUDE_CRYPTO_FBE := false

# UI / hardware
AERA_THEME := portrait_hdpi
AERA_EXTRA_LANGUAGES := true
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

# Logging
AERA_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
