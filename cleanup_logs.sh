#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-./logs}"

usage() {
  echo "Usage: $0 [--yes] [DAYS]"
  echo "    DAYS must be a non-negative integer (default: 7)"
}

YES=0
DAYS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
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

DAYS="${DAYS:-7}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  usage >&2
  exit 1
fi

LOGDIR="${LOGDIR:-./logs}"
mkdir -p "$LOGDIR"

echo "Looking for files in '$LOGDIR' older than ${DAYS} day(s)..."

mapfile -t files < <(find "$LOGDIR" -maxdepth 1 -type f -name "*.log" -mtime +"$DAYS" -print | sort || true)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No log files older than ${DAYS} day(s) found."
  exit 0
fi

echo
echo "The following files would be deleted:"
printf '    %s\n' "${files[@]}"
echo

if [ "$YES" -ne 1 ]; then
  read -r -p "Delete these files? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES) : ;;
    *) echo "Aborted. No files deleted."; exit 0 ;;
  esac
fi

echo "Deleting files..."
for f in "${files[@]}"; do
  if [ -f "$f" ]; then
    echo "  rm '$f'"
    rm -f -- "$f"
  fi
done
echo "Cleanup complete."
