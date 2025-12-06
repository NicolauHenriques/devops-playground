#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/log_search_${TS}.txt"

# ---- arguments ----
# $1 = pattern to search for (required)
# $2 = file to search in (optional, default: /var/log/syslog)

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 PATTERN [FILE]" >&2
  exit 1
fi

PATTERN="$1"
FILE="${2:-/var/log/syslog}"

# ---- do the search ----

if [ ! -r "$FILE" ]; then
  echo "ERROR: cannot read file '$FILE'" | tee "$OUT"
  exit 1
fi

matches_found=0

{
  echo "== Log Search @ $(date -Is) =="
  echo "pattern=${PATTERN}"
  echo "file=${FILE}"
  echo

  echo "## Last 20 matches (if any)"
  # -i = case-insensitive, -n = show line numbers
  if grep -i -n "$PATTERN" "$FILE" | tail -n 20; then
    matches_found=1
  else
    echo "No matches found."
  fi

} > "$OUT"

cat "$OUT"
echo "Saved to: $OUT"

# exit code logic:
# 0 = matches found, 1 = no matches
if [ "$matches_found" -eq 1 ]; then
  exit 0
else
  exit 1
fi
