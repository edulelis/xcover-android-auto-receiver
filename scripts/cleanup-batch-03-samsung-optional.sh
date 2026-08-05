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
    printf 'Unexpected device: %s. Cleanup cancelled.\n' "$model" >&2
    exit 1
    ;;
esac

# Optional Samsung features with no role in the Android Auto receiver. This batch excludes
# Routines, keyboard, camera, telephony, updater, Galaxy Store, System UI, and connectivity.
packages='com.samsung.android.bixby.agent
com.samsung.android.bixby.wakeup
com.samsung.android.bixbyvision.framework
com.samsung.android.app.settings.bixby
com.samsung.android.aremoji
com.samsung.android.arzone
com.samsung.android.app.dressroom
com.samsung.android.themestore
com.sec.android.app.sbrowser
com.sec.android.daemonapp
com.samsung.android.dynamiclock'

printf '%s\n' "$packages" | while IFS= read -r package_name; do
  if ! adb -s "$serial" shell pm path "$package_name" </dev/null 2>/dev/null | grep -q '^package:'; then
    printf 'missing          %s\n' "$package_name"
    continue
  fi

  if adb -s "$serial" shell pm list packages -d "$package_name" </dev/null |
    tr -d '\r' |
    grep -qx "package:$package_name"; then
    printf 'already disabled %s\n' "$package_name"
    continue
  fi

  adb -s "$serial" shell pm disable-user --user 0 "$package_name" </dev/null >/dev/null
  printf 'disabled         %s\n' "$package_name"
done
