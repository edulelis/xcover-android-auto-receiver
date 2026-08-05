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

# Use the window manager command so Samsung's rotation policy observes a real
# user-rotation lock instead of only seeing the backing settings change.
adb -s "$serial" shell wm user-rotation lock 1

printf 'accelerometer_rotation=%s\n' \
  "$(adb -s "$serial" shell settings get system accelerometer_rotation | tr -d '\r')"
printf 'user_rotation=%s\n' \
  "$(adb -s "$serial" shell settings get system user_rotation | tr -d '\r')"
printf 'wm_user_rotation=%s\n' \
  "$(adb -s "$serial" shell wm user-rotation | tr -d '\r')"
