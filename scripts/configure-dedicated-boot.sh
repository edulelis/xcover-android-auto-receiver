#!/bin/sh

set -eu

serial=${1:-}
package_name=com.andrerinas.headunitrevived.hfpslc
secure_permission=android.permission.WRITE_SECURE_SETTINGS

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

if ! adb -s "$serial" shell pm path "$package_name" 2>/dev/null | grep -q '^package:'; then
  printf 'Receiver is not installed: %s\n' "$package_name" >&2
  exit 1
fi

adb -s "$serial" shell locksettings set-disabled true
adb -s "$serial" shell pm grant "$package_name" "$secure_permission"
adb -s "$serial" shell settings put global adb_wifi_enabled 1

printf 'lockscreen_disabled=%s\n' \
  "$(adb -s "$serial" shell locksettings get-disabled | tr -d '\r')"
printf 'adb_wifi_enabled=%s\n' \
  "$(adb -s "$serial" shell settings get global adb_wifi_enabled | tr -d '\r')"
adb -s "$serial" shell dumpsys package "$package_name" |
  grep "$secure_permission" |
  tail -n 1 |
  tr -d '\r'
