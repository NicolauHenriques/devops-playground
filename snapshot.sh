#!/usr/bin/env bash
set -u  # gentle safety: error on unset variables

OUTDIR="${1:-./logs}"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/snapshot_${TS}.txt"

{
  echo "== Snapshot @ $(date -Is) =="
  echo "# User: $(whoami)  Host: $(hostname)"

  echo; echo "## OS"
  if [ -r /etc/os-release ]; then
    grep -E 'PRETTY_NAME|VERSION=' /etc/os-release
  else
    uname -a
  fi

  echo; echo "## Disk (top)"
  df -h | head -n 10

  echo; echo "## Memory"
  free -m

  echo; echo "## Listening sockets (top)"
  ss -tulpen 2>/dev/null | head -n 10 || echo "ss not available / permission denied"

  echo; echo "## Recent syslog (errors/warnings)"
  if [ -r /var/log/syslog ]; then
    grep -iE 'error|warn' /var/log/syslog | tail -n 25 || echo "no recent error/warn lines"
  else
    echo "/var/log/syslog not readable"
  fi
} | tee "$OUT"

echo "Saved to: $OUT"
