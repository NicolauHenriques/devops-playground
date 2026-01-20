#!/usr/bin/env bash
set -euo pipefail

echo "== Dev setup =="

# Ensure hooks path is configured for this repo
git config core.hooksPath .githooks
echo "git core.hooksPath -> $(git config core.hooksPath)"

# Ensure pre-commit hook is executable
if [ -f .githooks/pre-commit ]; then
  chmod +x .githooks/pre-commit
  echo "pre-commit hook is executable"
else
  echo "ERROR: .githooks/pre-commit not found"
  exit 1
fi

# Optional: show tool availability (doesn't install)
for cmd in shfmt shellcheck; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd: OK"
  else
    echo "$cmd: MISSING (install it: sudo apt-get install -y $cmd)"
  fi
done

echo "Done."
