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

adb -s "$serial" shell settings put global protect_battery 0
adb -s "$serial" shell settings put system screen_brightness_mode 0

printf 'Previous configuration restored.\n'
