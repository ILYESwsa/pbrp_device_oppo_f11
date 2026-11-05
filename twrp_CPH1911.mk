#
# SPDX-License-Identifier: Apache-2.0
#
# AERA (aera-16.0) product for OPPO F11. Lunch: twrp_CPH1911-bp2a-eng

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Common recovery configuration
$(call inherit-product, vendor/twrp/config/common.mk)

$(call inherit-product, device/oppo/CPH1911/device.mk)

PRODUCT_DEVICE := CPH1911
PRODUCT_NAME := twrp_CPH1911
PRODUCT_BRAND := oppo
PRODUCT_MODEL := F11
PRODUCT_MANUFACTURER := oppo
PRODUCT_RELEASE_NAME := CPH1911
