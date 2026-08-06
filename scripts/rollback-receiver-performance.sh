#!/bin/sh

set -eu

serial=${1:-}
package_name=com.andrerinas.headunitrevived.hfpslc

if [ -z "$serial" ]; then
  serial=$(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  device_count=$(printf '%s\n' "$serial" | awk 'NF { count++ } END { print count + 0 }')
  if [ "$device_count" -ne 1 ]; then
    printf 'Provide an ADB serial; %s devices were found.\n' "$device_count" >&2
    exit 1
  fi
fi

if ! adb -s "$serial" get-state 2>/dev/null | grep -qx device; then
  printf 'Device %s is not connected and authorized.\n' "$serial" >&2
  exit 1
fi

model=$(adb -s "$serial" shell getprop ro.product.model | tr -d '\r')
case "$model" in
  SM-G715U1) ;;
  *)
    printf 'Unexpected device: %s. Performance rollback cancelled.\n' "$model" >&2
    exit 1
    ;;
esac

if adb -s "$serial" shell pm path "$package_name" | grep -q '^package:'; then
  # Samsung's Android 13 shell rejects compile --reset because it clears profile data. Restore
  # Android's normal profile-guided filter instead, without deleting application data or profiles.
  adb -s "$serial" shell cmd package compile -m speed-profile -f "$package_name"
fi

adb -s "$serial" shell settings put global window_animation_scale 1.0
adb -s "$serial" shell settings put global transition_animation_scale 1.0
adb -s "$serial" shell settings delete global animator_duration_scale >/dev/null

printf 'window_animation_scale=%s\n' \
  "$(adb -s "$serial" shell settings get global window_animation_scale | tr -d '\r')"
printf 'transition_animation_scale=%s\n' \
  "$(adb -s "$serial" shell settings get global transition_animation_scale | tr -d '\r')"
printf 'animator_duration_scale=%s\n' \
  "$(adb -s "$serial" shell settings get global animator_duration_scale | tr -d '\r')"
if adb -s "$serial" shell pm path "$package_name" | grep -q '^package:'; then
  dexopt_line=$(adb -s "$serial" shell dumpsys package dexopt |
    sed -n "/\[$package_name\]/,+3p" |
    grep -m 1 'status=' || true)
  compiler_filter=$(printf '%s\n' "$dexopt_line" |
    sed -n 's/.*\[status=\([^]]*\)\].*/\1/p')
  printf 'compiler_filter=%s\n' "${compiler_filter:-unknown}"
fi
