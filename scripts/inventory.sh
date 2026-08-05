#!/bin/sh

set -eu

usage() {
  printf 'Usage: %s [adb-serial] [output-file]\n' "$0" >&2
}

serial=${1:-}
output=${2:-}

if [ "$serial" = "-h" ] || [ "$serial" = "--help" ]; then
  usage
  exit 0
fi

if [ -z "$serial" ]; then
  serial=$(
    adb devices |
      awk 'NR > 1 && $2 == "device" { print $1 }'
  )

  device_count=$(printf '%s\n' "$serial" | awk 'NF { count++ } END { print count + 0 }')
  if [ "$device_count" -ne 1 ]; then
    printf 'Provide an ADB serial: %s authorized devices were found.\n' "$device_count" >&2
    adb devices -l >&2
    exit 1
  fi
fi

if ! adb -s "$serial" get-state 2>/dev/null | grep -qx device; then
  printf 'Device %s is not connected and authorized.\n' "$serial" >&2
  exit 1
fi

if [ -z "$output" ]; then
  timestamp=$(date '+%Y%m%d-%H%M%S')
  output="artifacts/device-snapshots/xcover-${timestamp}.txt"
fi

output_dir=$(dirname "$output")
mkdir -p "$output_dir"

device_model=$(adb -s "$serial" shell getprop ro.product.model | tr -d '\r')
device_manufacturer=$(adb -s "$serial" shell getprop ro.product.manufacturer | tr -d '\r')

case "$device_manufacturer $device_model" in
  *[Ss]amsung*[Xx][Cc]over*|*[Ss]amsung*SM-G715*) ;;
  *)
    printf 'Unexpected device: %s %s (%s). Inventory cancelled.\n' \
      "$device_manufacturer" "$device_model" "$serial" >&2
    exit 1
    ;;
esac

adb_shell() {
  adb -s "$serial" shell "$@" | tr -d '\r'
}

property() {
  key=$1
  value=$(adb_shell getprop "$key")
  printf '%-38s %s\n' "$key" "$value"
}

setting() {
  namespace=$1
  key=$2
  value=$(adb_shell settings get "$namespace" "$key")
  printf '%-10s %-38s %s\n' "$namespace" "$key" "$value"
}

{
  printf '# XCover device snapshot (read-only)\n\n'
  printf 'captured_at_host=%s\n' "$(date -Iseconds)"
  case "$serial" in
    *:*) printf 'adb_transport=wireless\n' ;;
    *) printf 'adb_transport=usb_or_local\n' ;;
  esac
  printf 'adb_state=%s\n' "$(adb -s "$serial" get-state | tr -d '\r')"

  printf '\n## Identity and build\n'
  property ro.product.manufacturer
  property ro.product.model
  property ro.product.name
  property ro.product.device
  property ro.product.board
  property ro.soc.manufacturer
  property ro.soc.model
  property ro.build.version.release
  property ro.build.version.sdk
  property ro.build.version.security_patch
  property ro.build.version.oneui
  property ro.build.version.sem
  property ro.build.id
  property ro.build.display.id
  property ro.build.type
  property ro.build.tags
  property ro.boot.hardware
  property ro.boot.verifiedbootstate
  property ro.boot.vbmeta.device_state
  property ro.boot.flash.locked
  property ro.crypto.state
  property ro.crypto.type

  printf '\n## Battery\n'
  adb_shell dumpsys battery

  printf '\n## Charging protection and power\n'
  setting system protect_battery
  setting global protect_battery
  setting global adaptive_battery_management_enabled
  setting global low_power
  setting global stay_on_while_plugged_in

  printf '\n## Display and rotation\n'
  adb_shell wm size
  adb_shell wm density
  setting system screen_brightness_mode
  setting system screen_brightness
  setting system screen_off_timeout
  setting system accelerometer_rotation
  setting system user_rotation

  printf '\n## Location and connectivity (no SSIDs or paired devices)\n'
  setting secure location_mode
  setting global wifi_on
  setting global bluetooth_on
  setting global mobile_data

  printf '\n## Maintenance access (no keys or pairing codes)\n'
  setting global adb_enabled
  setting global adb_wifi_enabled
  setting global adb_allowed_connection_time
  printf 'lockscreen_disabled=%s\n' "$(adb_shell locksettings get-disabled)"

  printf '\n## Storage\n'
  adb_shell df -h /data

  printf '\n## Memory\n'
  adb_shell cat /proc/meminfo |
    grep -E '^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree):'

  printf '\n## Thermal state\n'
  adb_shell dumpsys thermalservice

  printf '\n## Default launcher\n'
  adb_shell cmd package resolve-activity --brief \
    -a android.intent.action.MAIN \
    -c android.intent.category.HOME

  printf '\n## System-declared features\n'
  adb_shell pm list features | sort

  printf '\n## User-installed packages\n'
  adb_shell pm list packages -3 | sort

  printf '\n## Disabled packages\n'
  adb_shell pm list packages -d | sort
} >"$output"

printf 'Inventory saved to %s\n' "$output"
