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

device_name=${XCOVER_PUBLIC_NAME:-XCover Receiver}

adb -s "$serial" shell "settings put global device_name '$device_name'"
adb -s "$serial" shell "settings put secure bluetooth_name '$device_name'"

printf 'device_name=%s\n' \
  "$(adb -s "$serial" shell settings get global device_name | tr -d '\r')"
printf 'bluetooth_name=%s\n' \
  "$(adb -s "$serial" shell settings get secure bluetooth_name | tr -d '\r')"
