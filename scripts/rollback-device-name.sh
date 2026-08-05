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

device_name='Galaxy XCover Pro'

adb -s "$serial" shell "settings put global device_name '$device_name'"
adb -s "$serial" shell "settings put secure bluetooth_name '$device_name'"

printf 'Previous public device name restored: %s\n' "$device_name"
