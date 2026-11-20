#!/usr/bin/env bash
# Verify Brim using ONLY files committed to the current branch.
# Works even when Codespaces contains old untracked trial ZIPs and WebPs.
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter is not installed in this Codespaces environment."
  exit 2
fi

root="$(git rev-parse --show-toplevel)"
branch="$(git -C "$root" branch --show-current)"
if [[ "$branch" != "feature/child-avatar-identity" ]]; then
  echo "ERROR: Expected feature/child-avatar-identity; on: $branch"
  exit 2
fi
commit="$(git -C "$root" rev-parse --short HEAD)"
work="$(mktemp -d "${TMPDIR:-/tmp}/natter-brim-v1-XXXXXXXX")"
trap 'rm -rf "$work"' EXIT

echo "Verifying committed Brim snapshot at $commit"
echo "Ignoring all untracked/local files; nothing will be committed or deployed."
git -C "$root" archive HEAD | tar -xf - -C "$work"
cd "$work"

echo "[1/4] Audit the committed Brim artwork..."
python3 tools/audit_brim_assets.py

echo "[2/4] Resolve Flutter dependencies for the isolated snapshot..."
flutter pub get

echo "[3/4] Run selection, widget and complete asset-bundle tests..."
flutter test test/brim_avatar* test/brim_asset_inventory_test.dart

echo "[4/4] Build the isolated Avatar Lab for web (no deployment)..."
flutter build web --profile -t lib/avatar/brim_lab_main.dart

echo
echo "BRIM V1 CLEAN BUILD VERIFIED: 27 assets, tests, profile web build."
echo "Source: $commit; main app, Firebase and live website unchanged."
