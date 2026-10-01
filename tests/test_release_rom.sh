#!/usr/bin/env bash
# Copyright (c) 2026 Md. Mehedi Hasan
# SPDX-License-Identifier: GPL-3.0-or-later
#
# End-to-end test for scripts/release_rom.sh.
#
# release_rom.sh chunks and uploads the release packages, generates the OTA
# manifest and commits it to the static_resources repo. This test drives that
# whole flow against a stubbed `gh` CLI and a stubbed generate_ota_manifest.sh,
# so it needs no network access and no GitHub credentials.
#
# Run it directly, or through the `ota-tests` job in .github/workflows/ci.yml:
#
#   tests/test_release_rom.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FAILED=0
TOTAL=0
pass() { printf '  ok   %s\n' "$1"; TOTAL=$((TOTAL + 1)); }
fail() { printf '  FAIL %s\n' "$1" >&2; TOTAL=$((TOTAL + 1)); FAILED=1; }
eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$3', got '$2')"; fi; }
ge() { if [ "$2" -ge "$3" ]; then pass "$1"; else fail "$1 (want >= $3, got '$2')"; fi; }
has() { if grep -qF -- "$2" <<<"$3"; then pass "$1"; else fail "$1 (missing: $2)"; fi; }
section() { printf '\n%s\n' "$1"; }

for tool in base64 git jq python3 unzip zip; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'missing required tool: %s\n' "$tool" >&2
    exit 2
  fi
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

VERSION=3.2.0
CODENAME=m51
STAMP=20260101

# --- stubbed GitHub CLI -----------------------------------------------------
# Records every request under $E2E_STATE and never touches the network. The
# first createCommitOnBranch call can be made to fail to exercise the retry.
write_stub_gh()
{
  cat > "$1" <<'STUB'
#!/usr/bin/env bash
set -uo pipefail
STATE="${E2E_STATE:?}"

if [ "${1:-}" = release ]; then
  case "${2:-}" in
    view)
      if [ -f "$STATE/released" ]; then echo '{}'; exit 0; else exit 1; fi ;;
    create) : > "$STATE/released"; exit 0 ;;
    upload) printf '%s\n' "$@" >> "$STATE/uploads"; exit 0 ;;
  esac
  exit 1
fi

url=""; graphql=0
for a in "$@"; do
  if [ "$a" = graphql ]; then graphql=1; fi
  case "$a" in repos/*) url="$a" ;; esac
done

if [ "$graphql" = 1 ]; then
  n="$(cat "$STATE/graphql_calls" 2>/dev/null || echo 0)"; n=$((n + 1)); echo "$n" > "$STATE/graphql_calls"
  cat > "$STATE/request.json"
  if [ "${E2E_FAIL_ALWAYS:-0}" = 1 ]; then
    echo "GraphQL: permanent failure from the API" >&2
    exit 1
  fi
  if [ "$n" -eq 1 ] && [ "${E2E_FAIL_FIRST:-0}" = 1 ]; then
    if [ "${E2E_CONCURRENT_ENTRY:-0}" = 1 ]; then
      printf '{"response": [{"filename": "concurrent-release.zip", "incremental": 0}]}\n' \
        > "$STATE/files/manifest-encrypted.json"
    fi
    echo "GraphQL: expectedHeadOid does not match" >&2
    exit 1
  fi
  while IFS=$'\t' read -r p c; do
    printf '%s' "$c" | base64 -d > "$STATE/files/$(basename "$p")"
  done < <(jq -r '.variables.i.fileChanges.additions[] | [.path, .contents] | @tsv' "$STATE/request.json")
  echo "$n" > "$STATE/head"
  echo "commitoid$n"
  exit 0
fi

case "$url" in
  */contents/*)
    for a in "$@"; do
      case "$a" in Accept:*raw*) echo x >> "$STATE/raw_requests" ;; esac
    done
    if [ "${E2E_FETCH_ERROR:-0}" = 1 ]; then
      echo "gh: Internal Server Error (HTTP 500)" >&2
      exit 1
    fi
    if [ "${E2E_VERIFY_FETCH_ERROR:-0}" = 1 ] && [ -f "$STATE/graphql_calls" ]; then
      echo "gh: Internal Server Error (HTTP 500)" >&2
      exit 1
    fi
    p="${url#*contents/}"; p="${p%%\?*}"
    f="$STATE/files/$(basename "$p")"
    if [ -f "$f" ]; then
      if [ "${E2E_TAMPER_MANIFEST:-0}" = 1 ]; then
        jq '.response[0].urls = ["https://example.invalid/tampered"]' "$f"
      else
        cat "$f"
      fi
      exit 0
    fi
    echo "gh: Not Found (HTTP 404)" >&2
    exit 1 ;;
  */git/ref/heads/*)
    if [ "${E2E_BRANCH_MISSING:-0}" = 1 ]; then
      echo "gh: Not Found (HTTP 404)" >&2
      exit 1
    fi
    cat "$STATE/head" 2>/dev/null || echo unknown; exit 0 ;;
esac
exit 1
STUB
  chmod +x "$1"
}

# --- test environment -------------------------------------------------------
setup_env()
{
  SCEN="$WORK/$1"; SRC="$SCEN/src"; OUT="$SCEN/out"; STATE="$SCEN/state"; BIN="$SCEN/bin"
  mkdir -p "$SRC/scripts" "$OUT" "$STATE/files" "$BIN" "$SCEN/ghconfig"
  cp "$REPO/scripts/release_rom.sh" "$SRC/scripts/release_rom.sh"
  cat > "$SRC/scripts/generate_ota_manifest.sh" <<'STUB'
#!/usr/bin/env bash
# Test double: emits the same manifest schema as the real generator.
set -euo pipefail
DIR="$1"; OUT="$SRC_DIR/manifest.json"
{
  echo '{'; echo '  "response": ['
  first=1
  for f in "$DIR"/*.zip; do
    [ "$first" -eq 1 ] || echo ','
    first=0
    info="$(unzip -p "$f" build_info.txt)"
    printf '    {"datetime": %s, "device": "%s", "filename": "%s", "id": "id", "patch": "%s", "size": %s, "urls": ["INSERTURLHERE"], "version": "%s", "incremental": %s}' \
      "$(grep '^timestamp' <<<"$info" | cut -d= -f2)" \
      "$(grep '^device' <<<"$info" | cut -d= -f2)" \
      "${f##*/}" \
      "$(grep '^security_patch_version' <<<"$info" | cut -d= -f2)" \
      "$(wc -c <"$f")" \
      "$(grep '^version' <<<"$info" | cut -d= -f2)" \
      "$(grep '^incremental' <<<"$info" | cut -d= -f2)"
  done
  echo; echo '  ]'; echo '}'
} > "$OUT"
STUB
  chmod +x "$SRC/scripts/generate_ota_manifest.sh"
  git -C "$SRC" init -q
  git -C "$SRC" config remote.origin.url "https://github.com/mehedihjoy0/UN1CA-SM7150"
  write_stub_gh "$BIN/gh"
}

mkzip() { # <outfile> <incremental>
  local d; d="$(mktemp -d)"
  printf 'version=%s\ntimestamp=1700000000\ndevice=%s\nsecurity_patch_version=2026-09-01\nincremental=%s\n' \
    "$VERSION" "$CODENAME" "$2" > "$d/build_info.txt"
  (cd "$d" && zip -q "$1" build_info.txt)
  rm -rf "$d"
}

target_zip() { echo "$OUT/${CODENAME}_${VERSION}-target_files-encrypted.zip"; }
full_zip() { echo "$OUT/UN1CA_${VERSION}_${STAMP}_${CODENAME}-encrypted-sign.zip"; }
delta_zip() { echo "$OUT/UN1CA_${VERSION}_${STAMP}_${CODENAME}_INCREMENTAL_4242-encrypted-sign.zip"; }
dec_target_zip() { echo "$OUT/${CODENAME}_${VERSION}-target_files-decrypted.zip"; }
dec_delta_zip() { echo "$OUT/UN1CA_${VERSION}_${STAMP}_${CODENAME}_INCREMENTAL_777-decrypted-sign.zip"; }

run_release() { # <changelog> <fail_first_commit>
  RELEASE_OUT="$(PATH="$BIN:$PATH" E2E_STATE="$STATE" E2E_FAIL_FIRST="$2" \
    E2E_FAIL_ALWAYS="${E2E_FAIL_ALWAYS:-0}" E2E_FETCH_ERROR="${E2E_FETCH_ERROR:-0}" \
    E2E_BRANCH_MISSING="${E2E_BRANCH_MISSING:-0}" E2E_TAMPER_MANIFEST="${E2E_TAMPER_MANIFEST:-0}" \
    E2E_CONCURRENT_ENTRY="${E2E_CONCURRENT_ENTRY:-0}" E2E_VERIFY_FETCH_ERROR="${E2E_VERIFY_FETCH_ERROR:-0}" \
    MAX_COMMIT_ATTEMPTS="${E2E_MAX_ATTEMPTS:-5}" \
    GH_CONFIG_DIR="$SCEN/ghconfig" GH_TOKEN=test-token \
    SRC_DIR="$SRC" OUT_DIR="$OUT" TARGET_CODENAME="$CODENAME" ROM_VERSION="$VERSION" \
    BUILD_TYPE="${E2E_BUILD_TYPE:--encrypted}" CHANGELOG_TEXT="$1" \
    bash "$SRC/scripts/release_rom.sh" 2>&1)"
  RELEASE_RC=$?
  MANIFEST="$STATE/files/manifest${E2E_BUILD_TYPE:--encrypted}.json"
}

# --- scenario: incremental release ------------------------------------------
section "Scenario: incremental release (full package + delta)"
setup_env incremental
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
mkzip "$(delta_zip)" 4242
echo "OLD CHANGELOG" > "$STATE/files/$VERSION.txt"

run_release "" 1
has "a lost commit race is retried" "Commit rejected, retrying" "$RELEASE_OUT"
has "the commit succeeds on a later attempt" "Commit done: commitoid2" "$RELEASE_OUT"
has "the pushed manifest is verified" "Verified 1 manifest entries on sixteen" "$RELEASE_OUT"
eq "the delta-only manifest has one entry" "$(jq -r '.response | length' "$MANIFEST")" "1"
if [[ "$(jq -r '.response[0].filename' "$MANIFEST")" == *INCREMENTAL* ]]; then
  pass "the manifest advertises the delta package, not the duplicate full one"
else
  fail "the manifest advertises the delta package, not the duplicate full one"
fi
if jq -e --arg prefix "https://github.com/mehedihjoy0/static_resources/releases/download/$VERSION/" '
  .response[0].urls[0] | startswith($prefix)' "$MANIFEST" >/dev/null 2>&1; then
  pass "download URLs are injected into the entry"
else
  fail "download URLs are injected into the entry"
fi
ge "the manifest is fetched with the raw media type" "$(wc -l < "$STATE/raw_requests" 2>/dev/null || echo 0)" 2
eq "a blank changelog leaves an existing file alone" "$(cat "$STATE/files/$VERSION.txt")" "OLD CHANGELOG"
eq "a blank changelog adds no file change" "$(jq -r '.variables.i.fileChanges.additions | length' "$STATE/request.json")" "1"

run_release "Fixed the OTA pipeline" 0
eq "a supplied changelog is written" "$(cat "$STATE/files/$VERSION.txt")" "Fixed the OTA pipeline"
eq "a supplied changelog adds a file change" "$(jq -r '.variables.i.fileChanges.additions | length' "$STATE/request.json")" "2"
eq "re-releasing keeps a single manifest entry" "$(jq -r '.response | length' "$MANIFEST")" "1"
if [ -f "$SRC/manifest.json" ]; then pass "the generated manifest lands at the source root"; else fail "the generated manifest lands at the source root"; fi

# --- scenario: full release -------------------------------------------------
section "Scenario: full release only"
setup_env full
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
run_release "Full release" 0
eq "the release succeeds" "$RELEASE_RC" "0"
eq "the full manifest has one entry" "$(jq -r '.response | length' "$MANIFEST")" "1"
eq "the entry is not incremental" "$(jq -r '.response[0].incremental' "$MANIFEST")" "0"
if jq -e '.response[0].urls[0] | contains("UN1CA_")' "$MANIFEST" >/dev/null 2>&1; then
  pass "the full package URL is injected"
else
  fail "the full package URL is injected"
fi

# --- scenario: missing artifacts --------------------------------------------
section "Scenario: missing artifacts fail fast"
setup_env missing_target
mkzip "$(full_zip)" 0
run_release "" 0
eq "a missing target-files zip fails" "$RELEASE_RC" "1"
has "the missing target-files zip is reported" "no target-files zip found for $VERSION" "$RELEASE_OUT"

setup_env missing_rom
mkzip "$(target_zip)" 0
run_release "" 0
eq "a missing ROM zip fails" "$RELEASE_RC" "1"
has "the missing ROM zip is reported" "no ROM zip found for $VERSION" "$RELEASE_OUT"

# --- scenario: transient fetch failure -------------------------------------
section "Scenario: a transient fetch error must not reset the manifest"
setup_env fetch_error
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
echo '{"response": [{"filename": "previously-released.zip"}]}' > "$STATE/files/manifest-encrypted.json"
E2E_FETCH_ERROR=1
run_release "" 0
E2E_FETCH_ERROR=0
eq "a transient fetch error fails the release" "$RELEASE_RC" "1"
has "the fetch failure is reported" "could not fetch manifest-encrypted.json from sixteen" "$RELEASE_OUT"
if [ -f "$STATE/graphql_calls" ]; then
  fail "no commit is attempted after a fetch error"
else
  pass "no commit is attempted after a fetch error"
fi
eq "the previous manifest content survives" "$(jq -r '.response[0].filename' "$STATE/files/manifest-encrypted.json")" "previously-released.zip"

# --- scenario: missing branch -----------------------------------------------
section "Scenario: a missing branch fails with a clear error"
setup_env branch_missing
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
E2E_BRANCH_MISSING=1
run_release "" 0
E2E_BRANCH_MISSING=0
eq "a missing branch fails the release" "$RELEASE_RC" "1"
has "the missing branch is reported" "could not resolve sixteen" "$RELEASE_OUT"

# --- scenario: stale artifacts of the other build type ----------------------
section "Scenario: artifacts are chosen by build type"
setup_env target_type
mkzip "$(target_zip)" 0
mkzip "$OUT/${CODENAME}_${VERSION}-target_files-decrypted.zip" 0
mkzip "$(full_zip)" 0
mkzip "$OUT/UN1CA_${VERSION}_${STAMP}_${CODENAME}-decrypted-sign.zip" 0
run_release "Release" 0
eq "the release succeeds with both build types present" "$RELEASE_RC" "0"
if grep -q "target_files-encrypted.zip" "$STATE/uploads" && ! grep -q "decrypted" "$STATE/uploads"; then
  pass "only the encrypted artifacts are uploaded"
else
  fail "only the encrypted artifacts are uploaded"
fi
eq "only one target zip is uploaded" "$(grep -c 'target_files' "$STATE/uploads")" "1"
eq "the manifest holds a single entry" "$(jq -r '.response | length' "$MANIFEST")" "1"
eq "the manifest entry is the encrypted package" "$(jq -r '.response[0].filename' "$MANIFEST")" "$(basename "$(full_zip)")"

# --- scenario: exhausted commit retries -------------------------------------
section "Scenario: an exhausted commit retry reports the underlying error"
setup_env retry_error
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
E2E_FAIL_ALWAYS=1
E2E_MAX_ATTEMPTS=2
run_release "" 0
E2E_FAIL_ALWAYS=0
E2E_MAX_ATTEMPTS=5
eq "a permanent commit failure fails the release" "$RELEASE_RC" "1"
has "the attempt count is reported" "could not commit manifest-encrypted.json after 2 attempts" "$RELEASE_OUT"
has "the underlying gh error is surfaced" "permanent failure from the API" "$RELEASE_OUT"

# --- scenario: missing environment variables --------------------------------
section "Scenario: a manual run without the CI environment fails helpfully"
setup_env usage
USAGE_OUT="$(PATH="$BIN:$PATH" E2E_STATE="$STATE" bash "$SRC/scripts/release_rom.sh" 2>&1)"
USAGE_RC=$?
eq "a manual run without variables fails" "$USAGE_RC" "1"
has "the missing variables are named" "missing required environment variable" "$USAGE_OUT"
has "SRC_DIR is listed as required" "SRC_DIR" "$USAGE_OUT"
has "OUT_DIR is listed as required" "OUT_DIR" "$USAGE_OUT"

# --- scenario: tampered manifest content ------------------------------------
section "Scenario: verification compares entry content, not just filenames"
setup_env tamper
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
E2E_TAMPER_MANIFEST=1
run_release "" 0
E2E_TAMPER_MANIFEST=0
eq "tampered manifest content fails the release" "$RELEASE_RC" "1"
has "the content mismatch is reported" "differ from what was committed" "$RELEASE_OUT"

# --- scenario: concurrent release during a retry ----------------------------
section "Scenario: a retry preserves a concurrent release's entries"
setup_env concurrent
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
E2E_CONCURRENT_ENTRY=1
run_release "" 1
E2E_CONCURRENT_ENTRY=0
eq "the release succeeds after the race" "$RELEASE_RC" "0"
has "the manifest is re-read before the retry" "Re-reading manifest-encrypted.json before retry" "$RELEASE_OUT"
eq "the concurrent entry survives the retry" "$(jq -r '[.response[] | select(.filename == "concurrent-release.zip")] | length' "$MANIFEST")" "1"
eq "this release's entry is present too" "$(jq -r '[.response[] | select(.filename | startswith("UN1CA_"))] | length' "$MANIFEST")" "1"
eq "the merged manifest holds both entries" "$(jq -r '.response | length' "$MANIFEST")" "2"

# --- scenario: verification fetch failure -----------------------------------
section "Scenario: a failed verification fetch reports the HTTP error"
setup_env verify_fetch_error
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
E2E_VERIFY_FETCH_ERROR=1
run_release "" 0
E2E_VERIFY_FETCH_ERROR=0
eq "a failed verification fetch fails the release" "$RELEASE_RC" "1"
has "the verification fetch failure is reported" "could not re-fetch manifest-encrypted.json" "$RELEASE_OUT"
has "the HTTP status is included" "HTTP 500" "$RELEASE_OUT"

# --- scenario: unusable git remote ------------------------------------------
section "Scenario: an unusable git remote fails with a clear error"
setup_env no_remote
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
git -C "$SRC" config --unset remote.origin.url || true
run_release "" 0
eq "a missing git remote fails the release" "$RELEASE_RC" "1"
has "the missing remote is reported" "could not derive a GitHub owner" "$RELEASE_OUT"

setup_env bad_remote
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
git -C "$SRC" remote set-url origin "https://gitlab.com/someone/UN1CA-SM7150"
run_release "" 0
eq "a non-GitHub remote fails the release" "$RELEASE_RC" "1"
has "the non-GitHub remote is reported" "could not derive a GitHub owner" "$RELEASE_OUT"

# --- scenario: full build-type matrix ---------------------------------------
section "Scenario: a full build-type matrix pass keeps the manifests separate"
setup_env matrix
mkzip "$(target_zip)" 0
mkzip "$(dec_target_zip)" 0
mkzip "$(full_zip)" 0
mkzip "$(delta_zip)" 4242
mkzip "$(dec_delta_zip)" 777

E2E_BUILD_TYPE=-encrypted run_release "Matrix changelog" 0
E2E_BUILD_TYPE=-decrypted run_release "Matrix changelog" 0
E2E_BUILD_TYPE=-encrypted

ENC="$STATE/files/manifest-encrypted.json"
DEC="$STATE/files/manifest-decrypted.json"
eq "the last matrix leg succeeded" "$RELEASE_RC" "0"
eq "both matrix legs committed their manifest" "$(cat "$STATE/graphql_calls")" "2"
eq "the encrypted manifest holds one entry" "$(jq -r '.response | length' "$ENC")" "1"
eq "the decrypted manifest holds one entry" "$(jq -r '.response | length' "$DEC")" "1"
eq "the encrypted manifest advertises the encrypted delta" "$(jq -r '.response[0].filename' "$ENC")" "$(basename "$(delta_zip)")"
eq "the decrypted manifest advertises the decrypted delta" "$(jq -r '.response[0].filename' "$DEC")" "$(basename "$(dec_delta_zip)")"
eq "the encrypted entry URL is correct" "$(jq -r '.response[0].urls[0]' "$ENC")" "https://github.com/mehedihjoy0/static_resources/releases/download/$VERSION/$(basename "$(delta_zip)")"
eq "the decrypted entry URL is correct" "$(jq -r '.response[0].urls[0]' "$DEC")" "https://github.com/mehedihjoy0/static_resources/releases/download/$VERSION/$(basename "$(dec_delta_zip)")"
if ! grep -q decrypted "$ENC" && ! grep -q encrypted "$DEC"; then
  pass "neither manifest leaks the other build type"
else
  fail "neither manifest leaks the other build type"
fi
eq "each leg uploaded its own target zip" "$(grep -cF 'target_files-encrypted.zip' "$STATE/uploads"):$(grep -cF 'target_files-decrypted.zip' "$STATE/uploads")" "1:1"
eq "both full packages are still uploaded" "$(grep -cF "$(basename "$(full_zip)")" "$STATE/uploads"):$(grep -cF "$(basename "$(delta_zip)")" "$STATE/uploads")" "1:1"
eq "the shared changelog was written" "$(cat "$STATE/files/$VERSION.txt")" "Matrix changelog"

# --- scenario: duplicate packages -------------------------------------------
section "Scenario: duplicate packages of the same build type fail the release"
setup_env duplicate_full
mkzip "$(target_zip)" 0
mkzip "$(full_zip)" 0
mkzip "$OUT/UN1CA_${VERSION}_20260102_${CODENAME}-encrypted-sign.zip" 0
run_release "" 0
eq "a duplicate full package fails the release" "$RELEASE_RC" "1"
has "the duplicate is reported" "more than one package matches this release" "$RELEASE_OUT"
has "the offending package is named" "$(basename "$(full_zip)")" "$RELEASE_OUT"
if [ -f "$STATE/uploads" ]; then
  fail "nothing is uploaded for a duplicate release"
else
  pass "nothing is uploaded for a duplicate release"
fi

setup_env duplicate_delta
mkzip "$(target_zip)" 0
mkzip "$(delta_zip)" 4242
mkzip "$OUT/UN1CA_${VERSION}_${STAMP}_${CODENAME}_INCREMENTAL_999-encrypted-sign.zip" 4242
run_release "" 0
eq "a duplicate delta package fails the release" "$RELEASE_RC" "1"
has "the duplicate delta is reported" "more than one package matches this release" "$RELEASE_OUT"

# --- scenario: generated manifest is ignored --------------------------------
section "Scenario: the generated manifest is ignored by git"
if git -C "$REPO" check-ignore -q manifest.json; then
  pass "manifest.json is git-ignored"
else
  fail "manifest.json is git-ignored"
fi

printf '\n%d checks, %d failed\n' "$TOTAL" "$FAILED"
if [ "$FAILED" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "PASSED"
