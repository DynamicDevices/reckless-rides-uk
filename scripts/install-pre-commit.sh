#!/usr/bin/env bash
# Install pre-commit hooks for Reckless Rides UK (reckless-rides-uk repo).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v pre-commit >/dev/null 2>&1; then
  echo "Installing pre-commit via pip..."
  pip3 install --user pre-commit
  export PATH="${HOME}/.local/bin:${PATH}"
fi

pre-commit install
echo ""
echo "Pre-commit hooks installed."
echo "  Manual run (all files):  pre-commit run --all-files"
echo "  Manual run (staged only): pre-commit run"
