#!/usr/bin/env bash
set -euo pipefail

CI_MODE=0
if [ "${1:-}" = "--ci" ]; then
  CI_MODE=1
fi

echo "== Smoke Test @ $(date -Is) =="

echo
echo "## 1) Lint"
make lint

echo
echo "## 2) Full health (quiet)"
./full_health.sh --quiet
echo "full_health(quiet) exit=$?"

echo
echo "## 3) Full health (normal)"
./full_health.sh >/dev/null
echo "full_health(normal) exit=$?"

echo
echo "## 4) systemd user unit sanity"
if [ "$CI_MODE" -eq 1 ] || [ -n "${CI:-}" ]; then
  echo "CI mode: skipping systemd checks."
else
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user show -p LoadState \
      devops-full-health.service \
      devops-cleanup-logs.service \
      devops-full-health.timer \
      devops-cleanup-logs.timer
  else
    echo "systemctl not found; skipping systemd checks."
  fi
fi

echo
echo "SMOKE: OK"
