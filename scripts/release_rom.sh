#!/usr/bin/env bash
# Copyright (c) 2026 Md. Mehedi Hasan
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail
shopt -s nullglob

echo "- Resolving repository"
REPOSITORY="$(git -C "$SRC_DIR" config --get remote.origin.url |
  sed -nE 's#^(https://github\.com/|git@github\.com:)([^/]+)/.*#\2#p')/static_resources"
BRANCH=sixteen
BUILD_TYPE="${BUILD_TYPE:-encrypted}"
BUILD_TYPE="-${BUILD_TYPE}"
RELEASE_WORK_DIR="$(mktemp -d)"
CHUNK_SIZE="${CHUNK_SIZE:-1610612736}"
RELEASE_CHUNKS_DIR="$RELEASE_WORK_DIR/chunks"
CHANGELOG_TEXT="${CHANGELOG_TEXT:-}"
MANIFEST_SRC_DIR="$OUT_DIR/.manifest_src"
cleanup() { rm -rf "$RELEASE_WORK_DIR" "$MANIFEST_SRC_DIR"; }
trap cleanup EXIT
mkdir -p "$RELEASE_CHUNKS_DIR"

# Only pick up artifacts belonging to the version being released, this
# prevents stale zips from previous builds from leaking into the release
# and into the OTA manifest
TARGET_FILES=("$OUT_DIR/${TARGET_CODENAME}_${ROM_VERSION}"-target*.zip)
if [ "${#TARGET_FILES[@]}" -eq 0 ]; then
  echo "ERROR: no target-files zip found for $ROM_VERSION in ${OUT_DIR/"$SRC_DIR"/}" >&2
  exit 1
fi
TARGET_FILE="${TARGET_FILES[0]}"; TARGET_NAME="${TARGET_FILE##*/}"

ROM_FILES=("$OUT_DIR"/UN1CA_"${ROM_VERSION}"_*.zip)
if [ "${#ROM_FILES[@]}" -eq 0 ]; then
  echo "ERROR: no ROM zip found for $ROM_VERSION in ${OUT_DIR/"$SRC_DIR"/}" >&2
  exit 1
fi

UPLOAD_PATHS=()
PREPARE_UPLOAD()
{
  local FILE="$1"
  local NAME="${FILE##*/}"
  if [ "$(wc -c < "$FILE")" -gt "$CHUNK_SIZE" ]; then
    split -b "$CHUNK_SIZE" -d -a 2 "$FILE" "$RELEASE_CHUNKS_DIR/$NAME."
    UPLOAD_PATHS+=("$RELEASE_CHUNKS_DIR/$NAME".*)
  else
    UPLOAD_PATHS+=("$FILE")
  fi
}

echo "- Preparing target: $TARGET_NAME"
PREPARE_UPLOAD "$TARGET_FILE"

for ROM_FILE in "${ROM_FILES[@]}"; do
  echo "- Releasing: ${ROM_FILE##*/}"
  PREPARE_UPLOAD "$ROM_FILE"
done

echo "- Generating OTA manifest"
rm -rf "$MANIFEST_SRC_DIR"
mkdir -p "$MANIFEST_SRC_DIR"
for ROM_FILE in "${ROM_FILES[@]}"; do
  # Hardlink (no extra disk usage), fall back to a copy across filesystems
  ln -f "$ROM_FILE" "$MANIFEST_SRC_DIR/" 2>/dev/null || cp -a "$ROM_FILE" "$MANIFEST_SRC_DIR/"
done
# The target-files zip is deliberately left out of MANIFEST_SRC_DIR so it never
# ends up in the OTA manifest, while staying in $OUT_DIR for the upload step
"$SRC_DIR/scripts/generate_ota_manifest.sh" "$MANIFEST_SRC_DIR"
MANIFEST="$SRC_DIR/manifest.json"

echo "- Injecting download URLs into manifest"
python3 - "$MANIFEST" "https://github.com/$REPOSITORY/releases/download/$ROM_VERSION" "$RELEASE_CHUNKS_DIR" <<'PY'
import glob, json, os, sys

manifest, prefix, chunks_dir = sys.argv[1:4]
with open(manifest, encoding="utf-8") as fh:
    data = json.load(fh)
for entry in data["response"]:
    name = entry["filename"]
    chunks = sorted(glob.glob(os.path.join(chunks_dir, name + ".*")))
    if chunks:
        entry["urls"] = [f"{prefix}/{os.path.basename(c)}" for c in chunks]
    else:
        entry["urls"] = [f"{prefix}/{name}"]
with open(manifest, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY

echo "- Creating release $ROM_VERSION"
gh release view "$ROM_VERSION" --repo "$REPOSITORY" >/dev/null 2>&1 ||
  gh release create "$ROM_VERSION" --repo "$REPOSITORY" --title "$ROM_VERSION" --notes "UN1CA $ROM_VERSION"

echo "- Uploading to release"
gh release upload "$ROM_VERSION" --repo "$REPOSITORY" --clobber "${UPLOAD_PATHS[@]}"

MANIFEST_NAME="manifest${BUILD_TYPE}.json"
MANIFEST_PATH="updates/$MANIFEST_NAME"
COMMIT_MESSAGE="updates: ${ROM_VERSION}${BUILD_TYPE}"
CURRENT_MANIFEST="$RELEASE_WORK_DIR/current_manifest.json"
UPDATED_MANIFEST="$RELEASE_WORK_DIR/updated_manifest.json"

echo "- Fetching current $MANIFEST_NAME"
gh api "repos/$REPOSITORY/contents/$MANIFEST_PATH?ref=$BRANCH" --jq .content 2>/dev/null |
  tr -d '\n' | base64 -d > "$CURRENT_MANIFEST" || true
[ -s "$CURRENT_MANIFEST" ] || echo '{"response":[]}' > "$CURRENT_MANIFEST"

echo "- Merging new entries into $MANIFEST_NAME"
python3 - "$CURRENT_MANIFEST" "$MANIFEST" "$UPDATED_MANIFEST" <<'PY'
import json, re, sys

current, new, out = sys.argv[1:4]
raw = open(current, encoding="utf-8").read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    data = json.loads(re.sub(r",(\s*[}\]])", r"\1", raw))
entries = json.load(open(new, encoding="utf-8"))["response"]
names = {entry["filename"] for entry in entries}
data["response"] = [
    entry for entry in data.get("response", []) if entry.get("filename") not in names
] + entries
with open(out, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
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
  --arg p2 "updates/$ROM_VERSION.txt" --arg c2 "$CHANGELOG_B64" \
  --arg msg "$COMMIT_MESSAGE" \
  '{query:$query,variables:{i:{
    branch:{repositoryNameWithOwner:$repo,branchName:$branch},
    message:{headline:$msg},
    fileChanges:{additions:[{path:$p1,contents:$c1},{path:$p2,contents:$c2}]},
    expectedHeadOid:$head
  }}}')"
COMMIT_OID="$(echo "$REQUEST_BODY" | gh api graphql --input - --jq .data.createCommitOnBranch.commit.oid)"
echo "- Commit done: $COMMIT_OID"

echo "- Verifying manifest update on $BRANCH"
REMOTE_SHA="$(gh api "repos/$REPOSITORY/git/ref/heads/$BRANCH" --jq .object.sha)"
if [ "$REMOTE_SHA" != "$COMMIT_OID" ]; then
  echo "ERROR: $BRANCH points at $REMOTE_SHA instead of the new commit $COMMIT_OID" >&2
  exit 1
fi
gh api "repos/$REPOSITORY/contents/$MANIFEST_PATH?ref=$BRANCH" --jq .content 2>/dev/null |
  tr -d '\n' | base64 -d > "$RELEASE_WORK_DIR/remote_manifest.json" || true
python3 - "$UPDATED_MANIFEST" "$RELEASE_WORK_DIR/remote_manifest.json" "$BRANCH" <<'PY'
import json, sys

local, remote, branch = sys.argv[1:4]
expected = {entry["filename"] for entry in json.load(open(local))["response"]}
try:
    actual = {entry["filename"] for entry in json.load(open(remote))["response"]}
except (FileNotFoundError, json.JSONDecodeError):
    print("ERROR: remote manifest could not be fetched or is invalid", file=sys.stderr)
    sys.exit(1)
missing = expected - actual
if missing:
    print(f"ERROR: entries missing from remote manifest: {sorted(missing)}", file=sys.stderr)
    sys.exit(1)
print(f"- Verified {len(expected)} manifest entries on {branch}")
PY

echo "===== Final $MANIFEST_NAME ====="; cat "$UPDATED_MANIFEST"; echo "===================="
