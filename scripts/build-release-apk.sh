#!/bin/sh

set -eu

usage() {
  printf 'Usage: ANDROID_HOME=/path/to/sdk %s <release-tag> [output-directory]\n' "$0" >&2
  printf 'Example: ANDROID_HOME=/path/to/Android/sdk %s v0.2.0\n' "$0" >&2
}

release_tag=${1:-}

if [ -z "$release_tag" ] || [ "$release_tag" = "-h" ] || [ "$release_tag" = "--help" ]; then
  usage
  [ -n "$release_tag" ] || exit 2
  exit 0
fi

case "$release_tag" in
  v[0-9]*.[0-9]*.[0-9]*) ;;
  *)
    printf 'Release tag must look like v0.2.0: %s\n' "$release_tag" >&2
    exit 2
    ;;
esac

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
release_dir=${2:-"$repo_root/tmp/release/$release_tag"}
android_sdk_root=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
upstream_commit=581a55f26fe74b2c93eae5778ddcd683eb08b113
expected_package=com.andrerinas.headunitrevived.hfpslc
expected_version_name=3.2.0-hfp-slc
expected_version_code=91
expected_certificate_sha256=${XCOVER_EXPECTED_CERT_SHA256:-bc31e8db447636a30d2f1f97bd8ca190b110c33395d2321690a995171e72eac1}

if [ -z "$android_sdk_root" ]; then
  printf 'ANDROID_HOME or ANDROID_SDK_ROOT must point to Android SDK 36.\n' >&2
  exit 2
fi

for required_command in git shasum awk sed find; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

aapt_bin=$(find "$android_sdk_root/build-tools" -type f -name aapt -perm -111 2>/dev/null | sort | tail -n 1)
apksigner_bin=$(find "$android_sdk_root/build-tools" -type f -name apksigner -perm -111 2>/dev/null | sort | tail -n 1)

if [ -z "$aapt_bin" ] || [ -z "$apksigner_bin" ]; then
  printf 'Android build-tools with aapt and apksigner were not found under %s.\n' "$android_sdk_root" >&2
  exit 1
fi

build_workspace=$(mktemp -d "${TMPDIR:-/tmp}/xcover-release-build.XXXXXX")
trap 'rm -rf "$build_workspace"' EXIT HUP INT TERM
source_dir="$build_workspace/open-headunit"

printf 'Cloning pinned Open Headunit source...\n'
git clone --quiet https://github.com/andreknieriem/open-headunit.git "$source_dir"
git -C "$source_dir" checkout --quiet "$upstream_commit"
git -C "$source_dir" apply "$repo_root/patches/open-headunit-hfp-slc.patch"
git -C "$source_dir" apply "$repo_root/patches/open-headunit-tpms-pairing.patch"

printf 'Running unit tests and assembling the GitHub debug APK...\n'
(
  cd "$source_dir"
  ANDROID_HOME="$android_sdk_root" \
  ANDROID_SDK_ROOT="$android_sdk_root" \
    ./gradlew :app:testGithubDebugUnitTest :app:assembleGithubDebug
)

built_apk="$source_dir/app/build/outputs/apk/github/debug/com.andrerinas.headunitrevived.hfpslc_3.2.0-hfp-slc_debug.apk"
if [ ! -f "$built_apk" ]; then
  printf 'Expected APK was not produced: %s\n' "$built_apk" >&2
  exit 1
fi

package_line=$($aapt_bin dump badging "$built_apk" | sed -n '1p')
case "$package_line" in
  *"name='$expected_package'"*"versionCode='$expected_version_code'"*"versionName='$expected_version_name'"*) ;;
  *)
    printf 'Unexpected APK identity:\n%s\n' "$package_line" >&2
    exit 1
    ;;
esac

certificate_report=$($apksigner_bin verify --verbose --print-certs "$built_apk")
certificate_sha256=$(printf '%s\n' "$certificate_report" |
  sed -n 's/^Signer #1 certificate SHA-256 digest: //p' |
  head -n 1)

if [ "$certificate_sha256" != "$expected_certificate_sha256" ]; then
  printf 'Signing certificate mismatch.\nExpected: %s\nActual:   %s\n' \
    "$expected_certificate_sha256" "$certificate_sha256" >&2
  printf 'Use the established maintainer debug keystore or intentionally plan a signing migration.\n' >&2
  exit 1
fi

mkdir -p "$release_dir"
artifact_name="open-headunit-tpms-xcover-${release_tag}-debug.apk"
release_apk="$release_dir/$artifact_name"
cp "$built_apk" "$release_apk"

apk_sha256=$(shasum -a 256 "$release_apk" | awk '{print $1}')
printf '%s  %s\n' "$apk_sha256" "$artifact_name" >"$release_dir/SHA256SUMS.txt"

{
  printf 'Release tag: %s\n' "$release_tag"
  printf 'Upstream commit: %s\n' "$upstream_commit"
  printf 'Package: %s\n' "$expected_package"
  printf 'Version name: %s\n' "$expected_version_name"
  printf 'Version code: %s\n' "$expected_version_code"
  printf 'APK SHA-256: %s\n' "$apk_sha256"
  printf 'Certificate SHA-256: %s\n' "$certificate_sha256"
  printf 'Signing note: Android debug certificate; manual sideload build\n'
} >"$release_dir/APK-METADATA.txt"

printf '\nRelease artifacts created in %s\n' "$release_dir"
printf 'APK: %s\n' "$release_apk"
printf 'SHA-256: %s\n' "$apk_sha256"
printf 'Certificate SHA-256: %s\n' "$certificate_sha256"
