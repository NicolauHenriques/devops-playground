#!/usr/bin/env bash
set -euo pipefail

# Optional global config
CONFIG="./config.sh"
if [ -r "$CONFIG" ]; then
  # shellcheck source=/dev/null
  . "$CONFIG"
fi

OUTDIR="./logs"

# Default days can now come from config (CLEANUP_LOGS_DAYS),
# but can still be overridden by the first CLI argument.
DEFAULT_DAYS="${CLEANUP_LOGS_DAYS:-7}"
DAYS="${1:-$DEFAULT_DAYS}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 [DAYS]"
  echo "    DAYS must be a non-negative integer (default: ${DEFAULT_DAYS})"
  exit 1
fi

if [ ! -d "$OUTDIR" ]; then
  echo "No '${OUTDIR}' directory found. Nothing to clean."
  exit 0
fi

echo "Looking for files in '${OUTDIR}' older than ${DAYS} day(s)..."

# Find candidate files
# -type f   = files
# -mtime +N = strictly older than N days
mapfile -t files < <(find "$OUTDIR" -type f -mtime +"$DAYS" -print | sort || true)

if [ "${#files[@]}"  -eq 0 ]; then
  echo "No log files older than ${DAYS} day(s) found."
  exit 0
fi

echo
echo "The following files would be deleted:"
printf '    %s\n' "${files[@]}"

echo
read -r -p "Delete these files? [y/N] " answer

case "$answer" in
  y|Y|yes|YES)
    echo "Deleting files..."
    # Use a loop so we can show each deletion
    for f in "${files[@]}"; do
      if [ -f "$f" ]; then
        echo "  rm '$f'"
        rm -f -- "$f"
      fi
    done
    echo "Cleanup complete."
    ;;
esac