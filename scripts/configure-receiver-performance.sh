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
android_release=$(adb -s "$serial" shell getprop ro.build.version.release | tr -d '\r')
case "$model $android_release" in
  'SM-G715U1 13') ;;
  *)
    printf 'Unexpected device: %s on Android %s. Performance configuration cancelled.\n' \
      "$model" "$android_release" >&2
    exit 1
    ;;
esac

if ! adb -s "$serial" shell pm path "$package_name" | grep -q '^package:'; then
  printf 'Receiver package is not installed: %s\n' "$package_name" >&2
  exit 1
fi

# Android deliberately downgrades runtime-debuggable apps to the verify filter and ignores their
# AOT output. Refuse to change animation settings until the installed dedicated build is eligible.
if adb -s "$serial" shell dumpsys package "$package_name" |
  grep -q 'flags=.*DEBUGGABLE'; then
  printf 'Installed receiver is runtime-debuggable; ART speed compilation is unavailable.\n' >&2
  exit 1
fi

# The dedicated receiver has ample storage. Compile all of its DEX code for startup speed rather
# than waiting for an idle profile-guided job. APK replacement invalidates this output, so rerun
# this script after every receiver update.
adb -s "$serial" shell cmd package compile -m speed -f "$package_name"

dexopt_line=$(adb -s "$serial" shell dumpsys package dexopt |
  sed -n "/\[$package_name\]/,+3p" |
  grep -m 1 'status=' || true)
compiler_filter=$(printf '%s\n' "$dexopt_line" |
  sed -n 's/.*\[status=\([^]]*\)\].*/\1/p')
if [ "$compiler_filter" != speed ]; then
  printf 'ART requested speed but the installed filter is %s.\n' \
    "${compiler_filter:-unknown}" >&2
  exit 1
fi

# Shorter system animations improve perceived response without removing the visual confirmation
# entirely. This does not change Android Auto transport or decoder timing.
adb -s "$serial" shell settings put global window_animation_scale 0.5
adb -s "$serial" shell settings put global transition_animation_scale 0.5
adb -s "$serial" shell settings put global animator_duration_scale 0.5

printf 'compiler_filter=%s\n' "$compiler_filter"
printf 'window_animation_scale=%s\n' \
  "$(adb -s "$serial" shell settings get global window_animation_scale | tr -d '\r')"
printf 'transition_animation_scale=%s\n' \
  "$(adb -s "$serial" shell settings get global transition_animation_scale | tr -d '\r')"
printf 'animator_duration_scale=%s\n' \
  "$(adb -s "$serial" shell settings get global animator_duration_scale | tr -d '\r')"
