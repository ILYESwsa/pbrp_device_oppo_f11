#
# SPDX-License-Identifier: Apache-2.0
#
# OPPO F11 (CPH1911, MT6771) - AERA bring-up, decryption disabled.

LOCAL_PATH := device/oppo/CPH1911

# Prebuilt 4 KiB-page ELF files must not be rejected by the 16 KiB page-size check.
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false

PRODUCT_COPY_FILES += \
    system/core/libprocessgroup/profiles/task_profiles.json:recovery/root/system/etc/task_profiles.json

$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# F11 launched on Android 9 (API 28); stock vendor is Android 11 (VNDK 30). Legacy non-A/B, no dynamic partitions.
PRODUCT_SHIPPING_API_LEVEL := 28
PRODUCT_TARGET_VNDK_VERSION := 30

$(call inherit-product, $(LOCAL_PATH)/aera_CPH1911.mk)

PRODUCT_PACKAGES_ENG += \
    tzdata_twrp

# MTP by default in recovery
PRODUCT_SYSTEM_PROPERTIES += \
    ro.sys.usb.storage.type=mtp \
    ro.mediatek.platform=MT6771

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.usb.config=mtp
