#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

LOGDIR="$tmp/logs"
BACKUPDIR="$tmp/backups"
mkdir -p "$LOGDIR" "$BACKUPDIR"

# --- cleanup_logs.sh behaviour ---
touch "$LOGDIR/new.log"
touch -d '10 days ago' "$LOGDIR/old.log"

LOGDIR="$LOGDIR" ./cleanup_logs.sh --yes 7

test -f "$LOGDIR/new.log"
test ! -f "$LOGDIR/old.log"

# --- backup_logs.sh behaviour (non-interactive) ---
echo "hello" > "$LOGDIR/example.log"
LOGDIR="$LOGDIR" BACKUPDIR="$BACKUPDIR" ./backup_logs.sh --yes 999

ls "$BACKUPDIR"/logs_backup_*.tar.gz >/dev/null

# --- arg validation checks (should fail) ---
if ./cleanup_logs.sh not_a_number >/dev/null 2>&1; then
  echo "Expected cleanup_logs.sh to fail on invalid DAYS" >&2
  exit 1
fi

if ./backup_logs.sh not_a_number >/dev/null 2>&1; then
  echo "Expected backup_logs.sh to fail on invalid DAYS" >&2
  exit 1
fi

echo "SMOKE TESTS: OK"
