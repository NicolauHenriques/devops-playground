#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

QUIET=0
if [ "${1:-}" = "--quiet" ]; then
  QUIET=1
fi

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/full_health_${TS}.txt"

# Defaults (used if env file doesn't provide them)
SERVICES_STR_DEFAULT="systemd-resolved.service"
NET_TARGETS_STR_DEFAULT="google.com https://google.com"

# Convert space-separated strings into arrays
read -r -a SERVICES    <<< "${SERVICES_STR:-$SERVICES_STR_DEFAULT}"
read -r -a NET_TARGETS <<< "${NET_TARGETS_STR:-$NET_TARGETS_STR_DEFAULT}"

overall=0   # 0=OK, 1=WARNING, 2=CRITICAL

# Decide output routing BEFORE running the report block
if [ "$QUIET" -eq 1 ]; then
  # Quiet: write report to file only
  : > "$OUT"
  exec 3>>"$OUT"
else
  # Normal: write to terminal AND file
  exec 3> >(tee "$OUT")
fi

# --- Report block (everything here writes to FD 3) ---
{
  echo "== Full Health Check @ $(date -Is) =="
  echo

  # ---- 1) System Health (disk + memory) ----
  echo "## System Health (disk + memory)"
  ./health.sh
  health_status=$?
  echo "health_status=${health_status}"
  echo

  if [ "$health_status" -gt "$overall" ]; then
    overall="$health_status"
  fi

  # ---- 2) Service Health ----
  echo "## Service Health"
  echo "Services: ${SERVICES[*]}"

  ./service_check.sh "${SERVICES[@]}"
  service_status=$?
  echo "service_status=${service_status}"
  echo

  if [ "$service_status" -gt "$overall" ]; then
    overall="$service_status"
  fi

  # ---- 3) Network Health ----
  echo "## Network Health"
  echo "Targets: ${NET_TARGETS[*]}"

  ./net_check.sh "${NET_TARGETS[@]}"
  net_status=$?
  echo "net_status=${net_status}"
  echo

  if [ "$net_status" -gt "$overall" ]; then
    overall="$net_status"
  fi

  # ---- Summary ----
  echo "Summary:"
  case "$overall" in
    0) echo "OVERALL: OK (system, services and network all healthy enough)" ;;
    1) echo "OVERALL: WARNING (some checks reported warning, none critical)" ;;
    2) echo "OVERALL: CRITICAL (one or more checks reported critical issues)" ;;
    *) echo "OVERALL: UNKNOWN (code ${overall})" ;;
  esac
} >&3

# Close FD 3
exec 3>&-

# In quiet mode, only print the report if overall != 0
if [ "$QUIET" -eq 1 ] && [ "$overall" -ne 0 ]; then
  cat "$OUT"
fi

echo "Saved to: $OUT"
exit "$overall"
