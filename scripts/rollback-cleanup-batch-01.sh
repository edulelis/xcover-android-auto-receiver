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

packages='com.facebook.appmanager
com.facebook.katana
com.facebook.services
com.facebook.system
com.microsoft.appmanager
com.microsoft.skydrive
com.netflix.mediaclient
com.netflix.partner.activation
com.samsung.shop
com.samsung.android.app.tips
com.sec.android.easyMover
com.sec.android.easyMover.Agent
com.samsung.android.smartswitchassistant
com.google.android.videos
com.google.android.apps.tachyon
com.google.android.apps.docs
com.google.android.apps.photos
com.dsi.ant.sample.acquirechannels
com.samsung.android.game.gamehome
com.samsung.android.game.gametools
com.samsung.android.app.spage
com.sec.android.usermanual
com.samsung.android.app.parentalcare'

printf '%s\n' "$packages" | while IFS= read -r package_name; do
  if ! adb -s "$serial" shell pm path "$package_name" </dev/null 2>/dev/null | grep -q '^package:'; then
    printf 'missing   %s\n' "$package_name"
    continue
  fi

  adb -s "$serial" shell pm enable --user 0 "$package_name" </dev/null >/dev/null
  printf 'enabled   %s\n' "$package_name"
done
