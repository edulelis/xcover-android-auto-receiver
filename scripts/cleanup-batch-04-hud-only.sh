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

# Local applications with no role on a dedicated Open Headunit receiver. This batch excludes
# One UI Home, Settings, System UI, keyboard, updater, providers, Google Play Services, and
# internal telephony, Bluetooth, and Wi-Fi components.
packages='com.android.chrome
com.google.android.gm
com.google.android.youtube
com.samsung.android.app.contacts
com.samsung.android.calendar
com.samsung.android.dialer
com.samsung.android.messaging
com.sec.android.app.camera
com.sec.android.app.clockpackage
com.sec.android.app.myfiles
com.sec.android.app.samsungapps
com.sec.android.gallery3d'

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
