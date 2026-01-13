#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-./logs}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

usage() {
  echo "Usage: $0 [--yes] [DAYS]"
  echo "    DAYS must be a non-negative integer (default: 14)"
}

YES=0
DAYS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes)
      YES=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      if [ -z "${DAYS}" ]; then
        DAYS="$1"
        shift
      else
        echo "ERROR: unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

DAYS="${DAYS:-14}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  usage >&2
  exit 1
fi

LOGDIR="${LOGDIR:-./logs}"
BACKUPDIR="${BACKUPDIR:-./backups}"

mkdir -p "$LOGDIR" "$BACKUPDIR"

TS="$(date +%F_%H-%M-%S)"
ARCHIVE="$BACKUPDIR/logs_backup_${TS}.tar.gz"

echo "Creating backup: $ARCHIVE"
tar -czf "$ARCHIVE" -C "$LOGDIR" .
echo "Backup created."

echo "Looking for backup archives older than ${DAYS} day(s) in '$BACKUPDIR'..."
mapfile -t old < <(find "$BACKUPDIR" -maxdepth 1 -type f -name "logs_backup_*.tar.gz" -mtime +"$DAYS" -print | sort || true)

if [ "${#old[@]}" -eq 0 ]; then
  echo "No old backup archives to delete."
  exit 0
fi

echo
echo "The following old backups will be deleted:"
printf '  %s\n' "${old[@]}"
echo

if [ "$YES" -ne 1 ]; then
  read -r -p "Delete these old backups? [y/N] " answer
  case "$answer" in
    y | Y | yes | YES) : ;;
    *)
      echo "Aborted backup cleanup. New backup kept, old backups untouched."
      exit 0
      ;;
  esac
fi

echo "Deleting old backups..."
for f in "${old[@]}"; do
  if [ -f "$f" ]; then
    echo "  rm '$f'"
    rm -f -- "$f"
  fi
done
echo "Old backup cleanup complete."
