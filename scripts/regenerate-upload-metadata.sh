#!/usr/bin/env bash
# Regenerate *_UPLOAD.json for an existing incident (from manifest + channel templates).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${1:?Usage: regenerate-upload-metadata.sh DEB-20260623T080303Z_53.4092N_2.9778W_001}"

MANIFEST="$ROOT/register/manifests/${BASE}_MANIFEST.json"
[[ -f "$MANIFEST" ]] || { echo "Missing manifest: $MANIFEST" >&2; exit 1; }

python3 "$ROOT/scripts/upload_metadata.py" from-manifest "$MANIFEST"
