#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/full_health_${TS}.txt"

#Default targets

SERVICES=("systemd-resolved.service")
NET_TARGETS=("google.com" "https://google.com")

overall=0   # 0=OK, 1=WARNING, 2=CRTICAL

{
    echo "== Full Health Check @ $(date -Is) =="
    echo


    # ---- 1)  System Health (disk + memory) ----
    echo "## System Health (disk + memory)"
    if ./health.sh; then
      health_status=$?
    else
      health_status=$?
    fi
    echo "health_status=${health_status}"
    echo

    if [ "$health_status" -gt "$overall" ]; then
      overall="$health_status"
    fi

    # ---- 2) Service Health ----
    echo "## Service Health"
    echo "Services: ${SERVICES[*]}"

    if ./service_check.sh "${SERVICES[@]}"; then
      service_status=$?
    else
      service_status=$?
    fi
    echo "service_status=${service_status}"
    echo

    if [ "$service_status" -gt "$overall" ]; then
      overall="$service_status"
    fi


    # ---- 3) Network Health ----
    echo "## Network Health"
    echo  "Targets: ${NET_TARGETS[*]}"

    if ./net_check.sh "${NET_TARGETS[@]}"; then
      net_status=$?
    else
      net_status=$?
    fi
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

} | tee "$OUT"

cat "$OUT"
echo "Saved to: $OUT"

exit "$overall"