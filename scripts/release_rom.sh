#!/usr/bin/env bash
# Copyright (c) 2026 Md. Mehedi Hasan
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail
shopt -s nullglob

echo "- Resolving repository"
REPOSITORY="$(git -C "$SRC_DIR" config --get remote.origin.url |
  sed -nE 's#^(https://github\.com/|git@github\.com:)([^/]+)/.*#\2#p')/static_resources"
BRANCH=sixteen VERSION="$ROM_VERSION"
RELEASE_WORK_DIR="$(mktemp -d)"; RELEASE_CHUNKS_DIR="$RELEASE_WORK_DIR/chunks"
mkdir -p "$RELEASE_CHUNKS_DIR"; trap 'rm -rf "$RELEASE_WORK_DIR"' EXIT
TARGET_FILES=("$OUT_DIR"/*target*.zip); TARGET_FILE="${TARGET_FILES[0]}"; TARGET_NAME="${TARGET_FILE##*/}"

if [ "${INCREMENTAL_OTA:-false}" = true ]; then
  echo "- Incremental OTA enabled"
  PREVIOUS_TAG="$(gh release list --repo "$REPOSITORY" --limit 100 --json tagName --jq '.[].tagName' |
    grep -vx "$VERSION" | head -n1 || true)"
  echo "  - Previous release: $PREVIOUS_TAG"

  SOURCE_BASE="$(gh release view "$PREVIOUS_TAG" --repo "$REPOSITORY" --json assets --jq '.assets[].name' |
    grep -E "target_files${TARGET_NAME#*target_files}\.00$" | head -n1 || true)"
  SOURCE_BASE="${SOURCE_BASE%.00}"

  echo "  - Downloading $SOURCE_BASE chunks from $PREVIOUS_TAG"
  gh release download "$PREVIOUS_TAG" --repo "$REPOSITORY" --pattern "$SOURCE_BASE.*" --dir "$RELEASE_WORK_DIR" --clobber
  cat "$RELEASE_WORK_DIR"/"$SOURCE_BASE".* > "$RELEASE_WORK_DIR/$SOURCE_BASE"

  echo "  - Building incremental OTA"
  ROM_FILE="$OUT_DIR/${TARGET_NAME%.zip}-INCREMENTAL.zip"
  "$SRC_DIR/scripts/internal/build_incremental_ota_zip.sh" "$RELEASE_WORK_DIR/$SOURCE_BASE" "$TARGET_FILE" "$ROM_FILE"
else
  ROM_FILES=("$OUT_DIR"/UN1CA*.zip); ROM_FILE="${ROM_FILES[0]}"
  echo "- Using full ROM: ${ROM_FILE##*/}"
fi

ROM_FILENAME="${ROM_FILE##*/}"

mv "$TARGET_FILE" "$SRC_DIR/"; TARGET_FILE="$SRC_DIR/$TARGET_NAME"

echo "- Splitting files into 1.5 GB chunks"
split -b 1610612736 -d -a 2 "$TARGET_FILE" "$RELEASE_CHUNKS_DIR/$TARGET_NAME."
split -b 1610612736 -d -a 2 "$ROM_FILE" "$RELEASE_CHUNKS_DIR/$ROM_FILENAME."

echo "- Generating OTA manifest"
set +u
"$SRC_DIR/scripts/generate_ota_manifest.sh" "$OUT_DIR"
set -u

MANIFEST="$SRC_DIR/manifest.json"

CHUNK_URLS=()
for CHUNK in "$RELEASE_CHUNKS_DIR/$ROM_FILENAME".*; do CHUNK_URLS+=("https://github.com/$REPOSITORY/releases/download/$VERSION/${CHUNK##*/}"); done

echo "- Injecting chunk URLs into manifest"
python3 - "$MANIFEST" "${CHUNK_URLS[@]}" <<'PY'
import sys
p,*u=sys.argv[1:];s=open(p,encoding="utf-8").read()
open(p,"w",encoding="utf-8").write(s.replace('["INSERTURLHERE"]',"["+",".join(f'"{x}"' for x in u)+"]",1))
PY

echo "- Creating release $VERSION"
gh release view "$VERSION" --repo "$REPOSITORY" >/dev/null 2>&1 ||
  gh release create "$VERSION" --repo "$REPOSITORY" --title "$VERSION" --notes "UN1CA $VERSION"

echo "- Uploading chunks to release"
gh release upload "$VERSION" --repo "$REPOSITORY" --clobber "$RELEASE_CHUNKS_DIR"/*

case "${BUILD_TYPE:-}" in
  encrypted) MANIFEST_NAME=manifest-encrypted.json ;;
  decrypted) MANIFEST_NAME=manifest-decrypted.json ;;
  *)         MANIFEST_NAME=manifest.json ;;
esac
case "${BUILD_TYPE:-}" in
  "") COMMIT_MESSAGE="updates: $VERSION" ;;
  *)  COMMIT_MESSAGE="updates: $VERSION-$BUILD_TYPE" ;;
esac

MANIFEST_PATH="updates/$MANIFEST_NAME"
CURRENT_MANIFEST="$RELEASE_WORK_DIR/current_manifest.json"
UPDATED_MANIFEST="$RELEASE_WORK_DIR/updated_manifest.json"

echo "- Fetching current $MANIFEST_NAME"
gh api "repos/$REPOSITORY/contents/$MANIFEST_PATH?ref=$BRANCH" --jq .content 2>/dev/null |
  tr -d '\n' | base64 -d > "$CURRENT_MANIFEST" || true
[ -s "$CURRENT_MANIFEST" ] || echo '{"response":[]}' > "$CURRENT_MANIFEST"

echo "- Merging new entry into $MANIFEST_NAME"
python3 - "$CURRENT_MANIFEST" "$MANIFEST" "$UPDATED_MANIFEST" <<'PY'
import json,re,sys
c,n,o=sys.argv[1:];s=open(c,encoding="utf-8").read()
try: j=json.loads(s)
except json.JSONDecodeError: j=json.loads(re.sub(r",(\s*[}\]])",r"\1",s))
e=json.load(open(n,encoding="utf-8"))["response"][0]
j["response"]=[x for x in j.get("response",[]) if x.get("filename")!=e["filename"]]+[e]
with open(o,"w",encoding="utf-8") as f: json.dump(j,f,indent=2,ensure_ascii=False); f.write("\n")
PY

echo "- Committing manifest and changelog"
GRAPHQL_QUERY="$(printf 'mutation(%si:CreateCommitOnBranchInput!){createCommitOnBranch(input:%si){commit{oid}}}' '$' '$')"
HEAD_SHA="$(gh api "repos/$REPOSITORY/git/ref/heads/$BRANCH" --jq .object.sha)"
CHANGELOG_B64="$(printf '%b\n' "$CHANGELOG_TEXT" | base64 -w0)"
MANIFEST_B64="$(base64 -w0 "$UPDATED_MANIFEST")"

REQUEST_BODY="$(jq -nc \
  --arg query "$GRAPHQL_QUERY" \
  --arg repo "$REPOSITORY" --arg branch "$BRANCH" --arg head "$HEAD_SHA" \
  --arg p1 "$MANIFEST_PATH" --arg c1 "$MANIFEST_B64" \
  --arg p2 "updates/$VERSION.txt" --arg c2 "$CHANGELOG_B64" \
  --arg msg "$COMMIT_MESSAGE" \
  '{query:$query,variables:{i:{
    branch:{repositoryNameWithOwner:$repo,branchName:$branch},
    message:{headline:$msg},
    fileChanges:{additions:[{path:$p1,contents:$c1},{path:$p2,contents:$c2}]},
    expectedHeadOid:$head
  }}}')"
echo "$REQUEST_BODY" | gh api graphql --input -
echo "- Commit done"

if [ -n "${PIXELDRAIN_API_KEY:-}" ]; then
  echo "- Uploading to PixelDrain"
  curl -sL https://github.com/jkawamoto/go-pixeldrain/releases/download/v0.7.6/pd_0.7.6_linux_amd64.tar.gz | tar -xz pd
  for FILE in "$OUT_DIR"/UN1CA*.zip "$SRC_DIR"/*target*.zip; do
    echo "  - $(basename "$FILE")"
    ./pd --api-key "$PIXELDRAIN_API_KEY" upload "$FILE" | sed 's|api/file|u|g'
  done
fi

echo "===== Final $MANIFEST_NAME ====="; cat "$UPDATED_MANIFEST"; echo "===================="