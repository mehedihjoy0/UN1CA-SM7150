#!/usr/bin/env bash
# Copyright (c) 2026 Md. Mehedi Hasan
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail
shopt -s nullglob

echo "- Resolving repository"
REPOSITORY="$(git -C "$SRC_DIR" config --get remote.origin.url |
  sed -nE 's#^(https://github\.com/|git@github\.com:)([^/]+)/.*#\2#p')/static_resources"
BUILD_WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_WORK_DIR"' EXIT

TARGET_FILES=("$OUT_DIR"/*target*.zip)
TARGET_FILE="${TARGET_FILES[0]}"; TARGET_NAME="${TARGET_FILE##*/}"

echo "- Incremental OTA enabled"
PREVIOUS_TAG="$(gh release list --repo "$REPOSITORY" --limit 100 --json tagName --jq '.[].tagName' |
  grep -vx "$ROM_VERSION" | head -n1 || true)"
[ -n "$PREVIOUS_TAG" ] || { echo "ERROR: no previous release found"; exit 1; }
echo "- Previous release: $PREVIOUS_TAG"

SOURCE_BASE="$(gh release view "$PREVIOUS_TAG" --repo "$REPOSITORY" --json assets --jq '.assets[].name' |
  grep -E "target_files${TARGET_NAME#*target_files}\.00$" | head -n1 || true)"
[ -n "$SOURCE_BASE" ] || { echo "ERROR: no source target_files in $PREVIOUS_TAG"; exit 1; }
SOURCE_BASE="${SOURCE_BASE%.00}"

echo "- Downloading $SOURCE_BASE chunks"
gh release download "$PREVIOUS_TAG" --repo "$REPOSITORY" --pattern "$SOURCE_BASE.*" --dir "$BUILD_WORK_DIR" --clobber
cat "$BUILD_WORK_DIR"/"$SOURCE_BASE".* > "$BUILD_WORK_DIR/$SOURCE_BASE"

echo "- Patching img2sdat"
perl -0777 -i -pe 's|^        (\(out_dir / f"\{tgt_image\.stem\}\.touched_src_ranges".*\n)        (\(out_dir / f"\{tgt_image\.stem\}\.touched_src_sha1".*)|        if b.touched_src_ranges:\n            $1            $2|m' "$TOOLS_DIR/bin/img2sdat"

echo "- Building incremental OTA"
shopt -s globstar
rm -f "$SRC_DIR"/**/installer/customize.sh "$SRC_DIR"/**/installer/install-end.edify
ROM_FILE="$OUT_DIR/rom.zip"
"$SRC_DIR/scripts/internal/build_incremental_ota_zip.sh" "$BUILD_WORK_DIR/$SOURCE_BASE" "$TARGET_FILE" "$ROM_FILE"

echo "- Naming incremental OTA"
BUILD_INFO="$(unzip -p "$ROM_FILE" "build_info.txt")"
TIMESTAMP="$(date -d "@$(grep "^timestamp" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)" "+%Y%m%d")"
INCREMENTAL="$(grep "^incremental" <<< "$BUILD_INFO" | cut -d "=" -f 2 -s)"
ROM_FILENAME="UN1CA_${ROM_VERSION}_${TIMESTAMP}_${TARGET_CODENAME}_INCREMENTAL_${INCREMENTAL}${BUILD_TYPE}-sign.zip"

mv "$ROM_FILE" "$OUT_DIR/$ROM_FILENAME"
echo "- Done: $OUT_DIR/$ROM_FILENAME"