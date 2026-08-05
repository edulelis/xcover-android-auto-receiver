#!/bin/sh

set -eu

usage() {
  printf 'Usage: %s <receiver-ip> [timeout-seconds]\n' "$0" >&2
  printf 'Or set XCOVER_ADB_IP and omit <receiver-ip>.\n' >&2
}

target_ip=${1:-${XCOVER_ADB_IP:-}}
timeout_seconds=${2:-60}
expected_model=${XCOVER_ADB_MODEL:-SM_G715U1}

if [ -z "$target_ip" ]; then
  usage
  exit 2
fi

case "$target_ip" in
  *[!0-9.]*|'')
    printf 'Invalid IP address: %s\n' "$target_ip" >&2
    exit 2
    ;;
esac

case "$timeout_seconds" in
  *[!0-9]*|'')
    printf 'Invalid timeout: %s\n' "$timeout_seconds" >&2
    exit 2
    ;;
esac

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/xcover-adb.XXXXXX")
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

connected_xcover() {
  adb devices -l |
    awk -v expected="model:$expected_model" \
      '$2 == "device" && index($0, expected) { print $1; exit }'
}

disconnect_stale_endpoints() {
  adb devices |
    awk -v prefix="$target_ip:" 'index($1, prefix) == 1 && $2 != "device" { print $1 }' |
    while IFS= read -r endpoint; do
      [ -n "$endpoint" ] || continue
      adb disconnect "$endpoint" </dev/null >/dev/null 2>&1 || true
    done
}

endpoint_from_adb_mdns() {
  adb mdns services 2>/dev/null |
    awk -v prefix="$target_ip:" \
      '$2 == "_adb-tls-connect._tcp" && index($3, prefix) == 1 { print $3; exit }'
}

endpoint_from_dns_sd() {
  browse_log="$temp_dir/browse.log"
  lookup_log="$temp_dir/lookup.log"
  : >"$browse_log"
  : >"$lookup_log"

  dns-sd -B _adb-tls-connect._tcp local. >"$browse_log" 2>&1 &
  browse_pid=$!
  sleep 2
  kill "$browse_pid" 2>/dev/null || true
  wait "$browse_pid" 2>/dev/null || true

  instance=$(awk '/ Add / { print $NF; exit }' "$browse_log")
  [ -n "$instance" ] || return 1

  dns-sd -L "$instance" _adb-tls-connect._tcp local. >"$lookup_log" 2>&1 &
  lookup_pid=$!
  sleep 2
  kill "$lookup_pid" 2>/dev/null || true
  wait "$lookup_pid" 2>/dev/null || true

  port=$(sed -n 's/.* can be reached at .*:\([0-9][0-9]*\) .*/\1/p' "$lookup_log" | head -n 1)
  [ -n "$port" ] || return 1
  printf '%s:%s\n' "$target_ip" "$port"
}

adb start-server >/dev/null
disconnect_stale_endpoints

existing=$(connected_xcover)
if [ -n "$existing" ]; then
  printf '%s\n' "$existing"
  exit 0
fi

started_at=$(date +%s)
while :; do
  endpoint=$(endpoint_from_adb_mdns || true)
  if [ -z "$endpoint" ]; then
    endpoint=$(endpoint_from_dns_sd || true)
  fi

  if [ -n "$endpoint" ]; then
    adb connect "$endpoint" </dev/null >/dev/null 2>&1 || true
    sleep 1
    connected=$(connected_xcover)
    if [ -n "$connected" ]; then
      printf '%s\n' "$connected"
      exit 0
    fi
  fi

  now=$(date +%s)
  elapsed=$((now - started_at))
  if [ "$elapsed" -ge "$timeout_seconds" ]; then
    printf 'XCover not found after %ss. Unlock the device, connect Wi-Fi, and enable Wireless debugging.\n' \
      "$timeout_seconds" >&2
    exit 1
  fi

  sleep 2
done
