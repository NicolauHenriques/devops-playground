#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_DIR="$HOME/.config/systemd/user"

mkdir -p "$UNIT_DIR"

echo "Copying units to: $UNIT_DIR"
cp -v "$SRC_DIR"/systemd/user/*.service "$UNIT_DIR"/
cp -v "$SRC_DIR"/systemd/user/*.timer "$UNIT_DIR"/

echo "Reloading user systemd..."
systemctl --user daemon-reload

echo "Enabling timers..."
systemctl --user enable --now devops-full-health.timer
systemctl --user enable --now devops-cleanup-logs.timer

echo
echo "Installed. Current timers:"
systemctl --user list-timers --all | grep devops || true
