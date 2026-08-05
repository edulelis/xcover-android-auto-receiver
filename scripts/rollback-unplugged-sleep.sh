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

# Values observed before configuration on 2026-08-04.
adb -s "$serial" shell settings put global stay_on_while_plugged_in 7
adb -s "$serial" shell settings put system screen_off_timeout 30000
adb -s "$serial" shell settings delete secure adaptive_sleep >/dev/null
adb -s "$serial" shell settings put system screen_brightness_mode 1
adb -s "$serial" shell settings put system screen_brightness 255
adb -s "$serial" shell settings put system screen_extra_brightness 0
adb -s "$serial" shell settings put system screen_auto_brightness_adj 1.0
adb -s "$serial" shell settings put secure reduce_bright_colors_activated 0
adb -s "$serial" shell settings delete global device_idle_constants >/dev/null

# No device_idle keys existed before this configuration. Deleting them restores the
# One UI defaults loaded by DeviceIdleController.
for key in \
  light_after_inactive_to \
  light_pre_idle_to \
  light_idle_to \
  light_max_idle_to \
  inactive_to \
  sensing_to \
  locating_to \
  motion_inactive_to \
  motion_inactive_to_flex \
  idle_after_inactive_to \
  idle_pending_to \
  max_idle_pending_to \
  idle_to \
  max_idle_to
do
  adb -s "$serial" shell device_config delete device_idle "$key" >/dev/null
done

adb -s "$serial" shell settings delete global adaptive_battery_management_enabled >/dev/null
adb -s "$serial" shell settings put global app_standby_enabled 1
adb -s "$serial" shell settings delete global app_auto_restriction_enabled >/dev/null
adb -s "$serial" shell settings delete global low_power_trigger_level >/dev/null

printf 'Previous unplugged sleep configuration restored.\n'
