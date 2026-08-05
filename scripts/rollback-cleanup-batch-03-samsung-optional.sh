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
    printf 'missing   %s\n' "$package_name"
    continue
  fi

  adb -s "$serial" shell pm enable --user 0 "$package_name" </dev/null >/dev/null
  printf 'enabled   %s\n' "$package_name"
done
