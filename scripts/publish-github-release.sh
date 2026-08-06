#!/bin/sh

set -eu

usage() {
  printf 'Usage: %s <release-tag> <apk-file> <release-notes-file>\n' "$0" >&2
  printf 'Example: %s v0.3.0 tmp/release/v0.3.0/open-headunit-tpms-xcover-v0.3.0-debug.apk docs/releases/v0.3.0.md\n' "$0" >&2
}

release_tag=${1:-}
apk_input=${2:-}
notes_input=${3:-}

if [ -z "$release_tag" ] || [ -z "$apk_input" ] || [ -z "$notes_input" ]; then
  usage
  exit 2
fi

case "$release_tag" in
  v[0-9]*.[0-9]*.[0-9]*) ;;
  *)
    printf 'Release tag must look like v0.3.0: %s\n' "$release_tag" >&2
    exit 2
    ;;
esac

for required_command in git gh shasum awk; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")

if [ ! -f "$apk_input" ]; then
  printf 'APK not found: %s\n' "$apk_input" >&2
  exit 1
fi

if [ ! -f "$notes_input" ]; then
  printf 'Release notes not found: %s\n' "$notes_input" >&2
  exit 1
fi

apk_dir=$(CDPATH='' cd -- "$(dirname -- "$apk_input")" && pwd)
apk_name=$(basename "$apk_input")
apk_file="$apk_dir/$apk_name"
checksum_file="$apk_dir/SHA256SUMS.txt"
metadata_file="$apk_dir/APK-METADATA.txt"

if [ ! -f "$checksum_file" ] || [ ! -f "$metadata_file" ]; then
  printf 'SHA256SUMS.txt and APK-METADATA.txt must exist beside the APK.\n' >&2
  exit 1
fi

expected_sha256=$(awk -v name="$apk_name" '$2 == name { print $1; exit }' "$checksum_file")
actual_sha256=$(shasum -a 256 "$apk_file" | awk '{print $1}')
if [ -z "$expected_sha256" ] || [ "$actual_sha256" != "$expected_sha256" ]; then
  printf 'APK checksum does not match %s.\n' "$checksum_file" >&2
  exit 1
fi

if [ -n "$(git -C "$repo_root" status --porcelain)" ]; then
  printf 'The Git working tree must be clean before publishing a release.\n' >&2
  git -C "$repo_root" status -sb >&2
  exit 1
fi

current_branch=$(git -C "$repo_root" branch --show-current)
current_commit=$(git -C "$repo_root" rev-parse HEAD)
if [ -z "$current_branch" ]; then
  printf 'A named Git branch is required.\n' >&2
  exit 1
fi

if ! git -C "$repo_root" rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
  printf 'The current branch has no upstream. Push it before publishing a release.\n' >&2
  exit 1
fi

upstream_remote=$(git -C "$repo_root" config --get "branch.$current_branch.remote")
if [ -z "$upstream_remote" ]; then
  printf 'The current branch has no configured upstream remote.\n' >&2
  exit 1
fi

if ! git -C "$repo_root" fetch --quiet "$upstream_remote"; then
  printf 'Unable to fetch the upstream remote: %s\n' "$upstream_remote" >&2
  exit 1
fi

ahead_count=$(git -C "$repo_root" rev-list --count '@{upstream}..HEAD')
behind_count=$(git -C "$repo_root" rev-list --count 'HEAD..@{upstream}')
if [ "$ahead_count" -ne 0 ] || [ "$behind_count" -ne 0 ]; then
  printf 'Local HEAD must exactly match the freshly fetched upstream (ahead=%s, behind=%s).\n' \
    "$ahead_count" "$behind_count" >&2
  exit 1
fi

gh auth status >/dev/null
repository_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
repository_visibility=$(gh repo view --json visibility --jq '.visibility')
repository_default_branch=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')

if [ "$repository_visibility" != "PUBLIC" ]; then
  printf 'Refusing to publish from a non-public repository: %s (%s)\n' \
    "$repository_name" "$repository_visibility" >&2
  exit 1
fi

if [ "$current_branch" != "$repository_default_branch" ]; then
  printf 'Release publication requires the default branch: current=%s, default=%s\n' \
    "$current_branch" "$repository_default_branch" >&2
  exit 1
fi

if git -C "$repo_root" rev-parse --verify "refs/tags/$release_tag" >/dev/null 2>&1; then
  printf 'Local tag already exists: %s\n' "$release_tag" >&2
  exit 1
fi

if git -C "$repo_root" ls-remote --exit-code --tags \
  "$upstream_remote" "refs/tags/$release_tag" >/dev/null 2>&1; then
  printf 'Remote tag already exists: %s\n' "$release_tag" >&2
  exit 1
fi

if gh release view "$release_tag" --repo "$repository_name" >/dev/null 2>&1; then
  printf 'Release already exists: %s\n' "$release_tag" >&2
  exit 1
fi

notes_dir=$(CDPATH='' cd -- "$(dirname -- "$notes_input")" && pwd)
notes_file="$notes_dir/$(basename "$notes_input")"

gh release create "$release_tag" \
  "$apk_file" \
  "$checksum_file" \
  "$metadata_file" \
  --repo "$repository_name" \
  --target "$current_commit" \
  --title "$release_tag" \
  --notes-file "$notes_file"

gh release view "$release_tag" \
  --repo "$repository_name" \
  --json url \
  --jq '.url'
