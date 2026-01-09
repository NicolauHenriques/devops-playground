#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_DIR="$HOME/.config/systemd/user"

CFG_DIR="$HOME/.config/devops-playground"
ENV_FILE="$CFG_DIR/devops-playground.env"
ENV_EXAMPLE="$SRC_DIR/systemd/user/devops-playground.env.example"

mkdir -p "$UNIT_DIR"
mkdir -p "$CFG_DIR"

if [ -f "$ENV_EXAMPLE" ]; then
  if [ ! -f "$ENV_FILE" ]; then
    echo "Installing env file to: $ENV_FILE"
    cp -v "$ENV_EXAMPLE" "$ENV_FILE"
  else
    echo "Env file already exists, leaving it untouched: $ENV_FILE"
  fi
else
  echo "WARNING: env example not found: $ENV_EXAMPLE"
fi

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
