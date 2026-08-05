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
    printf 'Unexpected device: %s. Rollback cancelled.\n' "$model" >&2
    exit 1
    ;;
esac

adb -s "$serial" shell locksettings set-disabled false
if adb -s "$serial" shell pm path "$package_name" 2>/dev/null | grep -q '^package:'; then
  adb -s "$serial" shell pm revoke "$package_name" "$secure_permission" 2>/dev/null || true
fi

printf 'lockscreen_disabled=%s\n' \
  "$(adb -s "$serial" shell locksettings get-disabled | tr -d '\r')"
printf 'Automatic ADB restoration was revoked; the current session was not interrupted.\n'
