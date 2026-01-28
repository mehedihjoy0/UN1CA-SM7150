#
# Copyright (C) 2025 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# UN1CA configuration file for Snapdragon devices (qssi)

# Galaxy A73 (Snapdragon) (One UI 8.0)
SOURCE_FIRMWARE="SM-A736B/XME/352828291234563"
SOURCE_EXTRA_FIRMWARES=()
SOURCE_PLATFORM_SDK_VERSION=36
SOURCE_PRODUCT_SHIPPING_API_LEVEL=31
SOURCE_BOARD_API_LEVEL=30
SOURCE_SUPER_GROUP_NAME="qti_dynamic_partitions"

# SEC Product Feature
SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION="07010"
SOURCE_AUDIO_SUPPORT_ACH_RINGTONE=false
SOURCE_AUDIO_SUPPORT_DUAL_SPEAKER=true
SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION=false
SOURCE_CAMERA_SUPPORT_CAMERAX_EXTENSION=true
SOURCE_CAMERA_SUPPORT_CUTOUT_PROTECTION=false
SOURCE_CAMERA_SUPPORT_MASS_APP_FLAVOR=true
SOURCE_CAMERA_SUPPORT_SDK_SERVICE=false
SOURCE_COMMON_CONFIG_MDNIE_MODE="55829"
SOURCE_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL=false
SOURCE_COMMON_SUPPORT_EMBEDDED_SIM=false
SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME="dvfs_policy_sm7325_xx"
SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_a73xq_sm7325"
SOURCE_FINGERPRINT_CONFIG_SENSOR="google_touch_display_optical,settings=3,no_delay_in_screen_off,transition_effect_on"
SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION="3"
SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS="3"
SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE="120"
# [
# Enable seamless refresh rate feature
# Check SOURCE/a73xq/patches/hfr/customize.sh for more info
SOURCE_LCD_CONFIG_HFR_MODE="2"
SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE="60,120"
SOURCE_LCD_CONFIG_SEAMLESS_BRT="149,84"
SOURCE_LCD_CONFIG_SEAMLESS_LUX="300,3500"
# ]
SOURCE_LCD_SUPPORT_MDNIE_HW=false
SOURCE_RIL_FEATURES="onebinary satellite_carrier"
SOURCE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT="1"
SOURCE_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG=false
# [
# Use custom booster value to improve Wi-Fi performance
SOURCE_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD="9999"
# ]