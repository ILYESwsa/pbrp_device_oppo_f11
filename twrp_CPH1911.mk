#
# SPDX-License-Identifier: Apache-2.0
#
# TWRP 14.1 product for OPPO F11. Lunch: twrp_CPH1911-ap2a-eng

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Common TWRP configuration
$(call inherit-product, vendor/twrp/config/common.mk)

$(call inherit-product, device/oppo/CPH1911/device.mk)

PRODUCT_DEVICE := CPH1911
PRODUCT_NAME := twrp_CPH1911
PRODUCT_BRAND := oppo
PRODUCT_MODEL := F11
PRODUCT_MANUFACTURER := oppo
PRODUCT_RELEASE_NAME := CPH1911

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="CPH1911-user 11 RP1A.200720.011 1705377488980 release-keys"

BUILD_FINGERPRINT := OPPO/CPH1911/OP4883:11/RP1A.200720.011/1705377488980:user/release-keys
