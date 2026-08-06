#!/bin/sh

set -eu

serial=${1:-}
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
case "$model" in
  SM-G715U1) ;;
  *)
    printf 'Unexpected device: %s. Launcher rollback cancelled.\n' "$model" >&2
    exit 1
    ;;
esac

if ! adb -s "$serial" shell pm path "$fallback_package" | grep -q '^package:'; then
  printf 'One UI Home is missing; launcher rollback cancelled.\n' >&2
  exit 1
fi

adb -s "$serial" shell pm enable "$fallback_package" >/dev/null
adb -s "$serial" shell cmd package set-home-activity --user 0 "$fallback_package"

resolved_home=$(adb -s "$serial" shell cmd package resolve-activity --components --user 0 \
  -a android.intent.action.MAIN \
  -c android.intent.category.HOME | tr -d '\r')
case "$resolved_home" in
  "$fallback_package"/*) printf 'default_home=%s\n' "$resolved_home" ;;
  *)
    printf 'One UI Home was not restored; resolved activity is %s\n' "$resolved_home" >&2
    exit 1
    ;;
esac
