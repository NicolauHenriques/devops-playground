#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/service_check_${TS}.txt"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 SERVICE [SERVICE...]" >&2
  exit 1
fi

echo "Checking services: $*"
echo

overall=0   # 0=OK, 1=WARNING, 2=CRITICAL

{
  echo "== Service Check @ $(date -Is) =="
  echo "Services: $*"
  echo

  for svc in "$@"; do
    echo "## $svc"

    # Get active state (don't kill the script if systemctl returns non-zero)
    active_state="$(systemctl is-active "$svc" 2>/dev/null || true)"
    if [ -z "$active_state" ]; then
      active_state="unknown"
    fi

    # Get enabled state (same idea)
    enabled_state="$(systemctl is-enabled "$svc" 2>/dev/null || true)"
    if [ -z "$enabled_state" ]; then
      enabled_state="unknown"
    fi


    echo "  active:  $active_state"
    echo "  enabled: $enabled_state"

    # Derive per-service status:
    # CRITICAL if not active
    # WARNING if active but not enabled
    # OK if active+enabled
    svc_status=0

    case "$active_state" in
      active)
        # service is running, now check enabled state
        case "$enabled_state" in
          enabled)
            svc_status=0
            ;;
          *)
            svc_status=1
            ;;
        esac
        ;;
      *)
        # inactive, failed, unknown, etc
        svc_status=2
        ;;
    esac

    echo "  status:  $svc_status"
    echo

    # bump overall to the worst we've seen so far
    if [ "$svc_status" -gt "$overall" ]; then
      overall="$svc_status"
    fi
  done

  echo "Summary:"
  case "$overall" in
    0) echo "OVERALL: OK (all services active and enabled)" ;;
    1) echo "OVERALL: WARNING (services active but some not enabled)" ;;
    2) echo "OVERALL: CRITICAL (one or more services inactive/failed/unknown)" ;;
    *) echo "OVERALL: UNKNOWN (code ${overall})" ;;
  esac
} > "$OUT"

cat "$OUT"
echo "Saved to: $OUT"

exit "$overall"
