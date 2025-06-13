#
# Copyright (C) 2011 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include device/google/gs-common/gps/brcm/device.mk
include device/google/gs-common/device.mk
include device/google/gs-common/gs_watchdogd/watchdog.mk
include device/google/gs-common/ramdump_and_coredump/ramdump_and_coredump.mk
include device/google/gs-common/soc/soc.mk
include device/google/gs-common/soc/freq.mk
include device/google/gs-common/modem/modem.mk
include device/google/gs-common/aoc/aoc.mk
include device/google/gs-common/thermal/dump/thermal.mk
include device/google/gs-common/thermal/thermal_hal/device.mk
include device/google/gs-common/pixel_metrics/pixel_metrics.mk
include device/google/gs-common/performance/perf.mk
include device/google/gs-common/power/power.mk
include device/google/gs-common/display/dump.mk
include device/google/gs-common/radio/dump.mk
include device/google/gs-common/gear/dumpstate/aidl.mk
include device/google/gs-common/camera/dump.mk
include device/google/gs-common/gps/dump/log.mk
include device/google/gs-common/widevine/widevine.mk
include device/google/gs-common/sota_app/factoryota.mk
include device/google/gs-common/misc_writer/misc_writer.mk
include device/google/gs-common/gyotaku_app/gyotaku.mk
include device/google/gs-common/bootctrl/bootctrl_aidl.mk
include device/google/gs-common/betterbug/betterbug.mk
ifneq ($(filter oriole raven bluejay, $(TARGET_PRODUCT)),)
  include device/google/gs-common/bcmbt/dump/dumplog.mk
endif
include device/google/gs-common/fingerprint/fingerprint.mk

TARGET_BOARD_PLATFORM := gs101
DEVICE_IS_64BIT_ONLY ?= $(if $(filter %_64,$(TARGET_PRODUCT)),true,false)

ifeq ($(DEVICE_IS_64BIT_ONLY),true)
LOCAL_64ONLY := _64
endif

AB_OTA_POSTINSTALL_CONFIG += \
	RUN_POSTINSTALL_system=true \
	POSTINSTALL_PATH_system=system/bin/otapreopt_script \
	FILESYSTEM_TYPE_system=ext4 \
POSTINSTALL_OPTIONAL_system=true

# Set Vendor SPL to match platform
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# Set boot SPL
BOOT_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

PRODUCT_SOONG_NAMESPACES += \
	hardware/google/av \
	hardware/google/gchips \
	hardware/google/graphics/common \
	hardware/google/gchips/gralloc4 \
	hardware/google/graphics/gs101 \
	hardware/google/interfaces \
	hardware/google/pixel \
	device/google/gs101

LOCAL_KERNEL := $(TARGET_KERNEL_DIR)/Image.lz4

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
#Set IKE logs to verbose for WFC
PRODUCT_PROPERTY_OVERRIDES += log.tag.IKE=VERBOSE

#Set Shannon IMS logs to debug
PRODUCT_PROPERTY_OVERRIDES += log.tag.SHANNON_IMS=DEBUG

#Set Shannon QNS logs to debug
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-ims=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-emergency=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-mms=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-xcap=DEBUG
PRODUCT_PROPERTY_OVERRIDES += log.tag.ShannonQNS-HC=DEBUG

# Modem userdebug
include device/google/gs101/modem/userdebug.mk
endif

include device/google/gs101/modem/user.mk

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
# b/36703476: Set default log size to 1M
PRODUCT_PROPERTY_OVERRIDES += \
	ro.logd.size=1M
# b/114766334: persist all logs by default rotating on 30 files of 1MiB
PRODUCT_PROPERTY_OVERRIDES += \
	logd.logpersistd=logcatd \
	logd.logpersistd.size=30
endif

USE_LASSEN_OEMHOOK := true
# The "power-anomaly-sitril" is added into PRODUCT_SOONG_NAMESPACES when
# $(USE_LASSEN_OEMHOOK) is true and $(BOARD_WITHOUT_RADIO) is not true.
ifneq ($(BOARD_WITHOUT_RADIO),true)
    $(call soong_config_set,sitril,use_lassen_oemhook_with_radio,true)
endif

# Use for GRIL
USES_LASSEN_MODEM := true
$(call soong_config_set, vendor_ril_google_feature, use_lassen_modem, true)

ifeq ($(USES_GOOGLE_DIALER_CARRIER_SETTINGS),true)
USE_GOOGLE_DIALER := true
USE_GOOGLE_CARRIER_SETTINGS := true
endif

# Audio client implementation for RIL
USES_GAUDIO := true

# ######################
# GRAPHICS - GPU (begin)

# Must match BOARD_USES_SWIFTSHADER in BoardConfig.mk
USE_SWIFTSHADER := false

# HWUI
TARGET_USES_VULKAN = true

# Used in gfx_tools when defining tests with composer2 interface for gs101 devices
$(call soong_config_set,gfx_tools,use_hwc2,true)

include device/google/gs-common/gpu/gpu.mk

# Install the OpenCL ICD Loader
PRODUCT_SOONG_NAMESPACES += external/OpenCL-ICD-Loader

# GRAPHICS - GPU (end)
# ####################

# Device Manifest, Device Compatibility Matrix for Treble
DEVICE_MANIFEST_FILE := \
	device/google/gs101/manifest$(LOCAL_64ONLY).xml

BOARD_USE_CODEC2_AIDL := V1
ifneq (,$(filter aosp_%,$(TARGET_PRODUCT)))
DEVICE_MANIFEST_FILE += \
	device/google/gs101/manifest_media_aosp.xml
else
DEVICE_MANIFEST_FILE += \
	device/google/gs101/manifest_media.xml
endif

DEVICE_MATRIX_FILE := \
	device/google/gs101/compatibility_matrix.xml

DEVICE_PACKAGE_OVERLAYS += \
	device/google/gs101/overlay \
	device/google/gs101/overlay-excluded-from-enforce-rro-targets

PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += \
	device/google/gs101/overlay-excluded-from-enforce-rro-targets

# Enforce the Product interface
PRODUCT_PRODUCT_VNDK_VERSION := current
PRODUCT_ENFORCE_PRODUCT_PARTITION_INTERFACE := true

# Init files
PRODUCT_COPY_FILES += \
	$(LOCAL_KERNEL):kernel

ifneq ($(BOARD_WITHOUT_RADIO),true)
PRODUCT_SOONG_NAMESPACES += device/google/gs101/conf
else
PRODUCT_SOONG_NAMESPACES += device/google/gs101/conf/nomodem
endif

include device/google/gs-common/insmod/insmod.mk

# For creating dtbo image
PRODUCT_HOST_PACKAGES += \
	mkdtimg

## HAL
include device/google/gs-common/chre/hal.mk

-include hardware/google/pixel/power-libperfmgr/aidl/device.mk

# IRQ rebalancing.
include hardware/google/pixel/rebalance_interrupts/rebalance_interrupts.mk

#
# Audio HALs
#

# Audio Configurations
USE_LEGACY_LOCAL_AUDIO_HAL := false
USE_XML_AUDIO_POLICY_CONF := 1

# Lyric Camera HAL settings
include device/google/gs-common/camera/lyric.mk
$(call soong_config_set,lyric,soc,gs101)
$(call soong_config_set,google3a_config,soc,gs101)

# Storage dump
include device/google/gs-common/storage/storage.mk

# Battery Mitigation
include device/google/gs-common/battery_mitigation/bcl.mk

# storage pixelstats
-include hardware/google/pixel/pixelstats/device.mk

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)

# Enforce generic ramdisk allow list
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Titan-M
ifeq (,$(filter true, $(BOARD_WITHOUT_DTLS)))
include device/google/gs-common/dauntless/gsc.mk
else
# include dauntless sepolicy to avoid compile error on devices without dauntless
BOARD_VENDOR_SEPOLICY_DIRS += device/google/gs-common/dauntless/sepolicy
endif

$(call soong_config_set,google_displaycolor,displaycolor_platform,gs101)

PRODUCT_CHARACTERISTICS := nosdcard

WIFI_PRIV_CMD_UPDATE_MBO_CELL_STATUS := enabled

####################################
## VIDEO
####################################

$(call soong_config_set,bigo,soc,gs101)

# 1. Codec 2.0
# for settings used by different C2 hal
include device/google/gs-common/mediacodec/common/mediacodec_common.mk
# for Exynos C2 Hal
include device/google/gs-common/mediacodec/samsung/mediacodec_samsung.mk

# CBD (CP booting deamon)
CBD_USE_V2 := true
CBD_PROTOCOL_SIT := true

# setup dalvik vm configs.
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

PRODUCT_TAGS += dalvik.gc.type-precise

# Trusty (KM, GK, Storage)
$(call inherit-product, system/core/trusty/trusty-storage.mk)
$(call inherit-product, system/core/trusty/trusty-base.mk)

# Trusty dump
include device/google/gs-common/trusty/trusty.mk

include device/google/gs101/trusty_metricsd/trusty_metricsd.mk

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Exynos RIL and telephony
# Multi SIM(DSDS)
SIM_COUNT := 2
$(call soong_config_set,sim,sim_count,$(SIM_COUNT))
SUPPORT_MULTI_SIM := true
# Support NR
SUPPORT_NR := true
# Using IRadio 1.6
USE_RADIO_HAL_1_6 := true
# Support SecureElement HAL for HIDL
USE_SE_HIDL := true

ifeq ($(DEVICE_IS_64BIT_ONLY),true)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
else
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
endif
include device/google/gs-common/sensors/sensors.mk
$(call soong_config_set,usf,target_soc,gs101)

# Audio
# Audio HAL Server & Default Implementations
include device/google/gs-common/audio/hidl_gs101.mk

$(call soong_config_set,aoc,target_soc,$(TARGET_BOARD_PLATFORM))
$(call soong_config_set,aoc,target_product,$(TARGET_PRODUCT))

$(call soong_config_set,android_hardware_audio,run_64bit,true)

# EdgeTPU
include device/google/gs-common/edgetpu/edgetpu.mk
# Config variables for TPU chip on device.
$(call soong_config_set,edgetpu_config,chip,abrolhos)

# pKVM
$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)
PRODUCT_BUILD_PVMFW_IMAGE := true

# Project
include hardware/google/pixel/common/pixel-common-device.mk

# Pixel Logger
include hardware/google/pixel/PixelLogger/PixelLogger.mk

ifneq ($(BOARD_WITHOUT_RADIO),true)
# Telephony
include device/google/gs101/telephony/user.mk
endif

# Wifi ext
include hardware/google/pixel/wifi_ext/device.mk

# Install product specific framework compatibility matrix
# (TODO: b/169535506) This includes the FCM for system_ext and product partition.
# It must be split into the FCM of each partition.
DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += device/google/gs101/device_framework_matrix_product.xml

# Hardware Info Collection
include hardware/google/pixel/HardwareInfo/HardwareInfo.mk

# Touch service
include device/google/gs-common/touch/twoshay/aidl_gs101.mk
include device/google/gs-common/touch/twoshay/twoshay.mk
