#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="./logs"
BACKUP_DIR="./backups"
DEFAULT_DAYS=14


DAYS="${1:-$DEFAULT_DAYS}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 [DAYS]"
  echo "    DAYS must be a non-negative integer (default: ${DEFAULT_DAYS})"
  exit 1
fi

if [ ! -d "$LOG_DIR" ]; then
  echo "No '${LOG_DIR}' directory found. Nothing to back up."
  exit 0
fi

mkdir -p "$BACKUP_DIR"

TS="$(date +%F_%H-%M-%S)"
ARCHIVE="${BACKUP_DIR}/logs_backup_${TS}.tar.gz"

echo "Creating backup: ${ARCHIVE}"
# -C changes directory so the archive has relative paths, not /full/paths
tar -czf "$ARCHIVE" -C "$LOG_DIR" .

echo "Backup created."

# Cleanup old backups
echo "Looking for backups archives older than ${DAYS} day(s) in '${BACKUP_DIR}'..."

mapfile -t old_archives < <(find "$BACKUP_DIR" -type f -name 'logs_backup_*.tar.gz' -mtime +"$DAYS" -print | sort || true)

if [ "${#old_archives[@]}" -eq 0 ]; then
  echo "No old backup archives to delete."
  exit 0
fi

echo
echo "The following old backups will be deleted:"
printf '  %s\n' "${old_archives[@]}"

echo
read -r -p "Delete these old backups? [y/N] " answer

case "$answer" in
  y|Y|yes|YES)
    echo "Deleting old backups..."
    for f in "${old_archives[@]}"; do
      if [ -f "$f" ]; then
        echo "  rm  '$f'"
        rm -f -- "$f"
      fi
    done
    echo "Old backup cleanup complete."
    ;;
  *)
    echo "Aborted backup cleanup. New backup kept, old backups untouched."
    ;;
esac