#!/usr/bin/env bash
set -euo pipefail

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
systemctl --user daemon-reload
systemctl --user show -p LoadState \
  devops-full-health.service \
  devops-cleanup-logs.service \
  devops-full-health.timer \
  devops-cleanup-logs.timer

echo
echo "SMOKE: OK"