---
title: Public repository and APK release process
status: current
last_verified: 2026-08-04
audience: maintainers and release operators
---

# Public repository and APK release process

## Outcome

Source, patches, scripts, maintained documentation, and sanitized evidence live in the public Git repository. APK binaries are attached to versioned GitHub Releases rather than committed to Git history.

Project policy treats every published tag and asset as immutable: corrections receive a new tag instead of replacing an existing file. Each release contains:

- the sideloadable APK;
- `SHA256SUMS.txt`;
- `APK-METADATA.txt` with package, upstream commit, version, APK hash, and certificate fingerprint;
- release notes committed under `docs/releases/`.

The release process has one non-negotiable order:

```text
draft → clean build → inspect → install that exact APK → verify →
finalize evidence → commit and push source → publish → download and verify
```

Never call an artifact physically verified unless that exact file was installed and exercised on the target receiver before publication.

## Signing boundary

The public APK is currently Android debug-signed for manual sideloading. Android accepts an in-place update only when the old and new APKs use the same certificate.

- **Official update-compatible publication:** requires the established maintainer private key, provisioned out of band at the debug-keystore path used by Gradle. The private key is intentionally absent from this repository.
- **Independent source reproduction:** may use another signing key for local testing, but the result cannot update the public APK and must not be published as an official update-compatible release.

The public certificate fingerprint is recorded in `apks/README.md`. Never commit, upload, print, or copy the private key or keystore into documentation.

## Prerequisites

Use macOS or Linux with:

- Git;
- GitHub CLI `gh`, authenticated with permission to publish the repository;
- a POSIX shell;
- JDK 17;
- Android platform-tools, including `adb`;
- Android SDK 36;
- Android build-tools containing `aapt` and `apksigner`;
- Android NDK `29.0.14206865`;
- the established maintainer signing key for an official release;
- a clean checkout of the published default branch.

Confirm the basic environment:

```sh
java -version
adb version
gh auth status
gh repo view --json nameWithOwner,visibility,url,defaultBranchRef
git status -sb
```

The repository must report `PUBLIC`, and the working tree must be clean before publication.

## Repeatable APK release

The examples below use `v0.2.0`. Replace it with one new semantic version and use the same value throughout:

```sh
release_tag=v0.2.0
release_dir="tmp/release/$release_tag"
apk_file="$release_dir/open-headunit-tpms-xcover-$release_tag-debug.apk"
notes_file="docs/releases/$release_tag.md"
```

The project release tag is independent of the embedded upstream-derived app version. Do not reuse, move, or overwrite a published tag.

### 1. Prove that the tag is unused

Fetch remote tags, then confirm the intended tag does not exist locally, remotely, or as a GitHub Release:

```sh
git fetch --tags origin

if git rev-parse --verify "refs/tags/$release_tag" >/dev/null 2>&1; then
  echo "Local tag already exists: $release_tag" >&2
  exit 1
fi

if git ls-remote --exit-code --tags origin "refs/tags/$release_tag" >/dev/null 2>&1; then
  echo "Remote tag already exists: $release_tag" >&2
  exit 1
fi

if gh release view "$release_tag" >/dev/null 2>&1; then
  echo "GitHub Release already exists: $release_tag" >&2
  exit 1
fi
```

The publication script repeats these checks and refuses to continue after a collision.

### 2. Prepare the release draft

Before building:

1. update both patches and verify them from a fresh upstream clone;
2. draft `docs/releases/<tag>.md` with intended changes and known limitations;
3. update `README.md` and `docs/user-guide.md` only when installation, compatibility, daily operation, or recovery changed;
4. identify which claims require physical-device evidence.

Do not add the final APK hash or claim physical verification yet.

### 3. Build from clean patches

```sh
ANDROID_HOME=/path/to/Android/sdk \
  scripts/build-release-apk.sh "$release_tag"
```

The build script:

1. creates a temporary clean workspace;
2. clones Open Headunit;
3. checks out pinned commit `581a55f26fe74b2c93eae5778ddcd683eb08b113`;
4. applies `open-headunit-hfp-slc.patch` and then `open-headunit-tpms-pairing.patch`;
5. runs the complete GitHub debug unit-test task;
6. assembles the APK;
7. verifies package name, version name, version code, and signing certificate;
8. writes the APK, checksum, and metadata under `tmp/release/<tag>/`.

The default certificate check intentionally fails when the established maintainer key is unavailable. Do not bypass that check for an official publication.

### 4. Inspect the release candidate

Expected files:

```text
tmp/release/<tag>/
├── APK-METADATA.txt
├── SHA256SUMS.txt
└── open-headunit-tpms-xcover-<tag>-debug.apk
```

Verify without leaving the repository root:

```sh
(
  cd "$release_dir"
  shasum -a 256 -c SHA256SUMS.txt
  sed -n '1,120p' APK-METADATA.txt
)
```

Confirm:

- checksum reports `OK`;
- package is `com.andrerinas.headunitrevived.hfpslc`;
- version name and code match the intended patch state;
- certificate SHA-256 matches `apks/README.md`;
- the asset name contains the intended project tag.

Stop on any mismatch.

### 5. Install and verify the exact candidate

Identify the physical receiver before installation:

```sh
adb devices -l
adb -s <receiver-serial> shell getprop ro.product.model
```

Continue only for the intended `SM-G715U1`. Install the exact candidate from the release directory:

```sh
adb -s <receiver-serial> install -r "$apk_file"
```

At minimum, verify:

- package version and certificate;
- application launch and dedicated home;
- phone selection and Android Auto projection;
- reconnection after one application restart;
- no startup crash;
- any user-visible behavior claimed in the release notes.

Use explicit evidence levels in the release record:

- **automated:** unit, contract, lint, or build checks;
- **emulator:** rendered or interacted on an emulator;
- **physical receiver:** exercised on the exact XCover target;
- **pending:** not completed or blocked by unavailable hardware.

Do not promote emulator or simulation evidence to a physical-hardware claim. A simulated TPMS alert does not prove a physical TPMS sensor.

After this candidate has been built and physically tested, freeze every APK input. Only release documentation and sanitized evidence may change. If either patch, `scripts/build-release-apk.sh`, an upstream input, or any other APK build input changes, discard the candidate and restart at step 3.

### 6. Finalize the release record

After candidate verification:

1. update `apks/README.md` with the exact APK hash, certificate, tag, and verification date;
2. update `docs/current-state.md` only for behavior observed from this exact artifact;
3. finalize `docs/releases/<tag>.md`, separating automated, emulator, physical, and pending checks;
4. add only sanitized screenshots or device evidence;
5. update maintained instructions when the operator workflow changed.

The APK and `tmp/` must remain ignored.

### 7. Review, commit, and push source first

Stage only the reviewed source, documentation, release notes, and sanitized evidence intended for this release. Then inspect both the working tree and the exact staged set:

```sh
git status -sb
git diff --check
git diff --stat
git diff --cached --check
git diff --cached --stat
git diff --cached --name-only
git status --ignored --short
```

Confirm that no APK, keystore, key, token, pairing code, BSSID, Bluetooth address, Wi-Fi Direct credential, account data, notification content, or unsanitized location screenshot is staged.

Commit the source, patches, scripts, final notes, and sanitized evidence, then push the default branch. The release script refuses a dirty tree, a missing upstream, or unpushed commits.

### 8. Publish the GitHub Release

From the repository root:

```sh
scripts/publish-github-release.sh \
  "$release_tag" \
  "$apk_file" \
  "$notes_file"
```

The script verifies:

- APK checksum;
- clean Git state;
- current branch is the repository default branch;
- local `HEAD` exactly matches its freshly fetched upstream;
- public repository visibility;
- absence of the tag locally and remotely;
- absence of an existing GitHub Release.

It then creates the tag and release at the current pushed commit and uploads the APK, checksum, and metadata.

### 9. Verify the public assets independently

```sh
gh release view "$release_tag" --json url,tagName,isDraft,isPrerelease,assets

release_check_dir=$(mktemp -d "${TMPDIR:-/tmp}/xcover-release-check.XXXXXX")
gh release download "$release_tag" --dir "$release_check_dir"
(
  cd "$release_check_dir"
  shasum -a 256 -c SHA256SUMS.txt
  sed -n '1,120p' APK-METADATA.txt
)
```

Compare the downloaded APK hash with the exact file physically tested in step 5. Open the repository and release while logged out when practical to confirm that both are genuinely public.

On a Windows verification workstation, compare the downloaded APK against `SHA256SUMS.txt` with:

```powershell
Get-FileHash .\open-headunit-tpms-xcover-<tag>-debug.apk -Algorithm SHA256
```

## First public repository publication

This section is needed only for a repository that does not already exist:

```sh
git init -b main
git add -A
git commit -m "Publish XCover Android Auto receiver project"

gh repo create <owner>/<repository> \
  --public \
  --source=. \
  --remote=origin \
  --description="Dedicated wireless Android Auto receiver for Samsung Galaxy XCover Pro"

git push -u origin main
```

Before the first commit, confirm that APKs, `tmp/`, keystores, credentials, BSSIDs, Bluetooth addresses, Wi-Fi Direct credentials, accounts, and unsanitized screenshots are absent from the staged file list.

## Install from a public release

Public installers should follow [the installation and operation guide](user-guide.md). The minimal command sequence is:

```sh
shasum -a 256 -c SHA256SUMS.txt
adb -s <receiver-serial> shell getprop ro.product.model
adb -s <receiver-serial> install -r \
  open-headunit-tpms-xcover-<tag>-debug.apk
```

The model must be `SM-G715U1`. Installation on other receivers is unverified.

## Failure and immutability rules

- Never publish a private key or keystore.
- Never commit APKs to Git history.
- Never use `gh release upload --clobber` to replace a published APK.
- Never move a published tag to another commit.
- If an asset is wrong, mark the affected release clearly and publish a corrected new tag.
- Never claim physical verification unless the exact candidate was installed and exercised before publication.
- Keep TPMS hardware, intercom audio, thermal endurance, ignition interruptions, and other open risks accurately labeled.

### Privacy incident exception

Published immutability does not require retaining personal or device-identifying data. If such data reaches a public commit, tag, release note, or asset:

1. remove or anonymize it in the current tree;
2. rotate any exposed credential immediately;
3. identify every branch, tag, release, and asset that retains the data;
4. rewrite public Git history only with explicit user authorization, using a generic no-reply commit identity;
5. force-update all affected public refs, then verify from an anonymous checkout;
6. contact GitHub Support when cached commit views or unreachable objects require expedited removal.

Do not use the privacy exception to replace an ordinary release artifact or hide non-sensitive project history.
