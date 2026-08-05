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

adb -s "$serial" shell settings put global protect_battery 1
adb -s "$serial" shell settings put system screen_brightness_mode 1

printf 'protect_battery=%s\n' \
  "$(adb -s "$serial" shell settings get global protect_battery | tr -d '\r')"
printf 'screen_brightness_mode=%s\n' \
  "$(adb -s "$serial" shell settings get system screen_brightness_mode | tr -d '\r')"
