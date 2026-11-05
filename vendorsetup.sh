#!/bin/bash
# AERA build settings for OPPO F11 (CPH1911). Usage: export AERA_BUILD_DEVICE=CPH1911

FDEVICE="CPH1911"

aera_get_target_device() {
    local chkdev
    chkdev=$(echo "$BASH_SOURCE" | grep -w "$FDEVICE")
    if [ -n "$chkdev" ]; then
        AERA_BUILD_DEVICE="$FDEVICE"
    else
        chkdev=$(set | grep BASH_ARGV | grep -w "$FDEVICE")
        [ -n "$chkdev" ] && AERA_BUILD_DEVICE="$FDEVICE"
    fi
}

if [ -z "$1" ] && [ -z "$AERA_BUILD_DEVICE" ]; then
    aera_get_target_device
fi

if [ "$1" = "$FDEVICE" ] || [ "$AERA_BUILD_DEVICE" = "$FDEVICE" ]; then
    export LC_ALL=C
    export AERA_PRODUCT_PREFIX=AERA
    export AERA_BUILD_STATUS=Unofficial
    export AERA_BUILD_TYPE=Alpha
    export AERA_VANILLA_BUILD=1
    export AERA_TARGET_DEVICES="CPH1911"
    export AERA_RECOVERY_BOOT_PARTITION="/dev/block/by-name/recovery"
    export AERA_RECOVERY_SYSTEM_PARTITION="/dev/block/by-name/system"
    export AERA_RECOVERY_VENDOR_PARTITION="/dev/block/by-name/vendor"

    export AERA_USE_TAR_BINARY=1
    export AERA_USE_SED_BINARY=1
    export AERA_USE_XZ_UTILS=1
    export AERA_USE_BASH_SHELL=1
    export AERA_ASH_IS_BASH=1
    export AERA_ENABLE_APP_MANAGER=1
    export AERA_DELETE_AROMAFM=1
    unset AERA_MAINTAINER_PATCH_VERSION
fi
