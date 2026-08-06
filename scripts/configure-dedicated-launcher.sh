#!/bin/sh

set -eu

serial=${1:-}
receiver_package=com.andrerinas.headunitrevived.hfpslc
fallback_package=com.sec.android.app.launcher

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
    printf 'Unexpected device: %s on Android %s. Launcher configuration cancelled.\n' \
      "$model" "$android_release" >&2
    exit 1
    ;;
esac

for package_name in "$receiver_package" "$fallback_package"; do
  if ! adb -s "$serial" shell pm path "$package_name" | grep -q '^package:'; then
    printf 'Required launcher package is missing: %s\n' "$package_name" >&2
    exit 1
  fi
done

if ! adb -s "$serial" shell cmd package query-activities --components --user 0 \
  -a android.intent.action.MAIN \
  -c android.intent.category.HOME |
  grep -q "^$receiver_package/"; then
  printf 'Installed receiver does not expose a HOME activity; install versionCode 92 or newer.\n' >&2
  exit 1
fi

# Keep One UI Home installed and enabled only as the recovery launcher. Daily app access stays in
# the receiver-owned drawer; the matching rollback script restores One UI Home as Android's HOME.
adb -s "$serial" shell pm enable "$fallback_package" >/dev/null
adb -s "$serial" shell cmd package set-home-activity --user 0 "$receiver_package"

resolved_home=$(adb -s "$serial" shell cmd package resolve-activity --components --user 0 \
  -a android.intent.action.MAIN \
  -c android.intent.category.HOME | tr -d '\r')
case "$resolved_home" in
  "$receiver_package"/*) printf 'default_home=%s\n' "$resolved_home" ;;
  *)
    printf 'Receiver was not selected as HOME; resolved activity is %s\n' "$resolved_home" >&2
    exit 1
    ;;
esac
