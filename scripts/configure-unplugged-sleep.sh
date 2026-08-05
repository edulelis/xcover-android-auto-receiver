#!/bin/sh

set -eu

serial=${1:-}

if [ -z "$serial" ]; then
  serial=$(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  device_count=$(printf '%s\n' "$serial" | awk 'NF { count++ } END { print count + 0 }')
  if [ "$device_count" -ne 1 ]; then
    printf 'Provide an ADB serial; %s devices were found.\n' "$device_count" >&2
    exit 1
  fi
fi

model=$(adb -s "$serial" shell getprop ro.product.model | tr -d '\r')
case "$model" in
  SM-G715*) ;;
  *)
    printf 'Unexpected device: %s. Configuration cancelled.\n' "$model" >&2
    exit 1
    ;;
esac

# Keep the screen awake while externally powered; use a short timeout when unplugged.
adb -s "$serial" shell settings put global stay_on_while_plugged_in 7
adb -s "$serial" shell settings put system screen_off_timeout 30000
adb -s "$serial" shell settings put secure adaptive_sleep 0

# Use maximum manual brightness. Extra Brightness is a supported Samsung option; firmware
# thermal limits remain active and are not modified.
adb -s "$serial" shell settings put system screen_brightness_mode 0
adb -s "$serial" shell settings put system screen_brightness 255
adb -s "$serial" shell settings put system screen_extra_brightness 1
adb -s "$serial" shell settings put secure reduce_bright_colors_activated 0

# Android 13 reads Device Idle timers from the DeviceConfig device_idle namespace.
# This XCover ignores the legacy Settings.Global value, so remove it instead of retaining
# a misleading setting. Deep Doze still requires the screen to be off, no external power,
# and a stationary device.
adb -s "$serial" shell settings delete global device_idle_constants >/dev/null

set_device_idle() {
  adb -s "$serial" shell device_config put device_idle "$1" "$2"
}

set_device_idle light_after_inactive_to 60000
set_device_idle light_pre_idle_to 30000
set_device_idle light_idle_to 300000
set_device_idle light_max_idle_to 900000
set_device_idle inactive_to 120000
set_device_idle sensing_to 60000
set_device_idle locating_to 30000
set_device_idle motion_inactive_to 120000
set_device_idle motion_inactive_to_flex 30000
set_device_idle idle_after_inactive_to 300000
set_device_idle idle_pending_to 60000
set_device_idle max_idle_pending_to 300000
set_device_idle idle_to 900000
set_device_idle max_idle_to 21600000

adb -s "$serial" shell settings put global adaptive_battery_management_enabled 1
adb -s "$serial" shell settings put global app_standby_enabled 1
adb -s "$serial" shell settings put global app_auto_restriction_enabled 1
adb -s "$serial" shell settings put global low_power_trigger_level 20

printf 'stay_on_while_plugged_in=%s\n' \
  "$(adb -s "$serial" shell settings get global stay_on_while_plugged_in | tr -d '\r')"
printf 'screen_off_timeout=%s\n' \
  "$(adb -s "$serial" shell settings get system screen_off_timeout | tr -d '\r')"
printf 'adaptive_sleep=%s\n' \
  "$(adb -s "$serial" shell settings get secure adaptive_sleep | tr -d '\r')"
printf 'screen_brightness_mode=%s\n' \
  "$(adb -s "$serial" shell settings get system screen_brightness_mode | tr -d '\r')"
printf 'screen_brightness=%s\n' \
  "$(adb -s "$serial" shell settings get system screen_brightness | tr -d '\r')"
printf 'screen_extra_brightness=%s\n' \
  "$(adb -s "$serial" shell settings get system screen_extra_brightness | tr -d '\r')"
printf 'device_idle_config:\n'
adb -s "$serial" shell device_config list device_idle | sort
