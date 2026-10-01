#!/usr/bin/env bash
# Copyright (c) 2026 Md. Mehedi Hasan
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail
shopt -s nullglob

# This script is driven by the release CI, which exports these from the build
# environment. Fail with a usable message instead of an unbound-variable error.
REQUIRED_VARS=(SRC_DIR OUT_DIR TARGET_CODENAME ROM_VERSION)
MISSING_VARS=()
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR:-}" ]; then
    MISSING_VARS+=("$VAR")
  fi
done
if [ "${#MISSING_VARS[@]}" -ne 0 ]; then
  echo "ERROR: missing required environment variable(s): ${MISSING_VARS[*]}" >&2
  echo "Run this script from the release workflow (.github/workflows/ci.yml) or export:" >&2
  printf '  %s\n' "${REQUIRED_VARS[@]}" >&2
  exit 1
fi
unset REQUIRED_VARS MISSING_VARS VAR

echo "- Resolving repository"
REMOTE_URL="$(git -C "$SRC_DIR" config --get remote.origin.url 2>/dev/null || true)"
OWNER="$(sed -nE 's#^(https://github\.com/|git@github\.com:)([^/]+)/.*#\2#p' <<< "$REMOTE_URL")"
if [ -z "$OWNER" ]; then
  echo "ERROR: could not derive a GitHub owner from the git remote of $SRC_DIR" >&2
  echo "  remote.origin.url: ${REMOTE_URL:-<unset>}" >&2
  exit 1
fi
REPOSITORY="$OWNER/static_resources"
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
# and into the OTA manifest. Prefer the target-files zip for this build type so
# a leftover zip of the other encryption state can never be the one uploaded;
# fall back to any suffix for builds that do not append one.
TARGET_FILES=("$OUT_DIR/${TARGET_CODENAME}_${ROM_VERSION}"-target*"${BUILD_TYPE}".zip)
if [ "${#TARGET_FILES[@]}" -eq 0 ]; then
  TARGET_FILES=("$OUT_DIR/${TARGET_CODENAME}_${ROM_VERSION}"-target*.zip)
fi
if [ "${#TARGET_FILES[@]}" -eq 0 ]; then
  echo "ERROR: no target-files zip found for $ROM_VERSION in ${OUT_DIR/"$SRC_DIR"/}" >&2
  exit 1
fi
TARGET_FILE="${TARGET_FILES[0]}"; TARGET_NAME="${TARGET_FILE##*/}"

# Same as the target-files zip: a leftover package of the other encryption
# state must never be uploaded or advertised in the manifest
ROM_FILES=("$OUT_DIR"/UN1CA_"${ROM_VERSION}"_*"${BUILD_TYPE}"*.zip)
if [ "${#ROM_FILES[@]}" -eq 0 ]; then
  ROM_FILES=("$OUT_DIR"/UN1CA_"${ROM_VERSION}"_*.zip)
fi
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
entries = data["response"]
# An incremental release must advertise exactly one update per version: the
# delta package. The full package is still uploaded to the release (so users
# who cannot apply deltas can grab it manually), but listing both would make
# the updater offer the same version twice.
if any(entry.get("incremental") for entry in entries):
    entries = [entry for entry in entries if entry.get("incremental")]
    data["response"] = entries
for entry in entries:
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

# Read the manifest as it exists on the branch. Called before every commit
# attempt so a retry re-merges and preserves entries added by a concurrent
# release instead of clobbering them with a stale copy.
FETCH_CURRENT_MANIFEST()
{
  echo "- Fetching current $MANIFEST_NAME"
  # Use the raw media type: the default JSON response returns content="" and
  # encoding="none" for files over 1 MiB, which would silently reset the manifest.
  FETCH_ERR="$RELEASE_WORK_DIR/manifest_fetch.err"
  if gh api -H "Accept: application/vnd.github.raw" \
    "repos/$REPOSITORY/contents/$MANIFEST_PATH?ref=$BRANCH" > "$CURRENT_MANIFEST" 2> "$FETCH_ERR"; then
    # A 200 with an empty body means the manifest is corrupt; merging on top of
    # it would drop every entry without any warning
    if [ ! -s "$CURRENT_MANIFEST" ]; then
      echo "ERROR: $MANIFEST_NAME on $BRANCH is empty" >&2
      exit 1
    fi
  # Only a 404 means the manifest does not exist yet. Any other failure (network
  # blip, 5xx, expired token) must abort: falling back to an empty manifest would
  # silently replace the whole history with this release alone.
  elif grep -q "HTTP 404" "$FETCH_ERR"; then
    echo '{"response":[]}' > "$CURRENT_MANIFEST"
  else
    echo "ERROR: could not fetch $MANIFEST_NAME from $BRANCH" >&2
    cat "$FETCH_ERR" >&2
    exit 1
  fi
}

# Fold this release's entries into the current manifest, replacing any entry
# that shares its filename
MERGE_MANIFEST()
{
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
}

echo "- Committing manifest and changelog"
GRAPHQL_QUERY="$(printf 'mutation(%si:CreateCommitOnBranchInput!){createCommitOnBranch(input:%si){commit{oid}}}' '$' '$')"
# Only write updates/<version>.txt when a changelog was actually supplied:
# committing an empty file would wipe the changelog of an existing release.
CHANGELOG_B64=""
if [ -n "${CHANGELOG_TEXT//[[:space:]]/}" ]; then
  CHANGELOG_B64="$(printf '%b\n' "$CHANGELOG_TEXT" | base64 -w0)"
fi
MAX_COMMIT_ATTEMPTS="${MAX_COMMIT_ATTEMPTS:-5}"
COMMIT_ERR="$RELEASE_WORK_DIR/commit.err"
REF_ERR="$RELEASE_WORK_DIR/branch_ref.err"

# Every release commits to the same branch in the static_resources repo, so a
# build can lose the race and have createCommitOnBranch rejected because
# expectedHeadOid is no longer the branch tip. Re-read the tip *and* re-fetch and
# re-merge the manifest on every attempt, so entries added by a concurrent
# release are preserved instead of being clobbered.
COMMIT_OID=""
for ((ATTEMPT = 1; ATTEMPT <= MAX_COMMIT_ATTEMPTS; ATTEMPT++)); do
  if [ "$ATTEMPT" -gt 1 ]; then
    echo "- Re-reading $MANIFEST_NAME before retry $ATTEMPT/$MAX_COMMIT_ATTEMPTS"
  fi
  FETCH_CURRENT_MANIFEST
  MERGE_MANIFEST
  MANIFEST_B64="$(base64 -w0 "$UPDATED_MANIFEST")"

  if ! HEAD_SHA="$(gh api "repos/$REPOSITORY/git/ref/heads/$BRANCH" --jq .object.sha 2> "$REF_ERR")" ||
    [ -z "$HEAD_SHA" ] || [ "$HEAD_SHA" = "null" ]; then
    echo "ERROR: could not resolve $BRANCH in $REPOSITORY" >&2
    if [ -s "$REF_ERR" ]; then cat "$REF_ERR" >&2; fi
    exit 1
  fi
  REQUEST_BODY="$(jq -nc \
    --arg query "$GRAPHQL_QUERY" \
    --arg repo "$REPOSITORY" --arg branch "$BRANCH" --arg head "$HEAD_SHA" \
    --arg p1 "$MANIFEST_PATH" --arg c1 "$MANIFEST_B64" \
    --arg p2 "updates/$ROM_VERSION.txt" --arg c2 "$CHANGELOG_B64" \
    --arg msg "$COMMIT_MESSAGE" \
    '{query:$query,variables:{i:{
      branch:{repositoryNameWithOwner:$repo,branchName:$branch},
      message:{headline:$msg},
      fileChanges:{additions:([{path:$p1,contents:$c1}]
        + (if $c2 == "" then [] else [{path:$p2,contents:$c2}] end))},
      expectedHeadOid:$head
    }}}')"
  if COMMIT_OID="$(echo "$REQUEST_BODY" | gh api graphql --input - --jq .data.createCommitOnBranch.commit.oid 2> "$COMMIT_ERR")" &&
    [ -n "$COMMIT_OID" ] && [ "$COMMIT_OID" != "null" ]; then
    break
  fi
  COMMIT_OID=""
  echo "- Commit rejected, retrying ($ATTEMPT/$MAX_COMMIT_ATTEMPTS)" >&2
  if [ "$ATTEMPT" -lt "$MAX_COMMIT_ATTEMPTS" ]; then
    sleep "$ATTEMPT"
  fi
done
if [ -z "$COMMIT_OID" ]; then
  echo "ERROR: could not commit $MANIFEST_NAME after $MAX_COMMIT_ATTEMPTS attempts" >&2
  if [ -s "$COMMIT_ERR" ]; then cat "$COMMIT_ERR" >&2; fi
  exit 1
fi
echo "- Commit done: $COMMIT_OID"

echo "- Verifying manifest update on $BRANCH"
# The branch tip must not be required to equal $COMMIT_OID: a concurrent release
# may have committed right after us. The invariant that matters is that the
# manifest on $BRANCH carries exactly the entries we committed, which still
# catches force-push resets and lost writes.

REMOTE_MANIFEST="$RELEASE_WORK_DIR/remote_manifest.json"
VERIFY_ERR="$RELEASE_WORK_DIR/manifest_verify.err"
if ! gh api -H "Accept: application/vnd.github.raw" \
  "repos/$REPOSITORY/contents/$MANIFEST_PATH?ref=$BRANCH" > "$REMOTE_MANIFEST" 2> "$VERIFY_ERR"; then
  echo "ERROR: could not re-fetch $MANIFEST_NAME from $BRANCH for verification" >&2
  cat "$VERIFY_ERR" >&2
  exit 1
fi
python3 - "$UPDATED_MANIFEST" "$REMOTE_MANIFEST" "$BRANCH" <<'PY'
import json, sys

local, remote, branch = sys.argv[1:4]
try:
    expected = {e["filename"]: e for e in json.load(open(local))["response"]}
except (FileNotFoundError, json.JSONDecodeError):
    print("ERROR: local manifest is invalid", file=sys.stderr)
    sys.exit(1)
try:
    actual = {e["filename"]: e for e in json.load(open(remote))["response"]}
except (FileNotFoundError, json.JSONDecodeError):
    print("ERROR: remote manifest could not be fetched or is invalid", file=sys.stderr)
    sys.exit(1)
missing = sorted(set(expected) - set(actual))
if missing:
    print(f"ERROR: entries missing from remote manifest: {missing}", file=sys.stderr)
    sys.exit(1)
# Compare the entries themselves, not only their filenames: a truncated write or
# a mutated URL would otherwise pass verification unnoticed
mismatched = sorted(name for name, entry in expected.items() if actual[name] != entry)
if mismatched:
    print(f"ERROR: entries differ from what was committed: {mismatched}", file=sys.stderr)
    sys.exit(1)
print(f"- Verified {len(expected)} manifest entries on {branch}")
PY

echo "===== Final $MANIFEST_NAME ====="; cat "$UPDATED_MANIFEST"; echo "===================="
