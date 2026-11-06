#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/oppo/CPH1911

TARGET_OTA_ASSERT_DEVICE := CPH1911

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# F11 launched on Android 9 (API 28); stock vendor is Android 11 (VNDK 30). Legacy non-A/B.
PRODUCT_SHIPPING_API_LEVEL := 28
PRODUCT_TARGET_VNDK_VERSION := 30

PRODUCT_PACKAGES_ENG += \
    tzdata_twrp

# MTP by default in recovery
PRODUCT_SYSTEM_PROPERTIES += \
    ro.sys.usb.storage.type=mtp \
    ro.mediatek.platform=MT6771

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.usb.config=mtp
