#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/net_check_${TS}.txt"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 HOST_OR_URL [HOST_OR_URL...]" >&2
  exit 1
fi

overall=0 # 0 =OK, 1=WARNING, 2=CRITICAL

{
  echo "== Network Check @ $(date -Is) =="
  echo "Targets: $*"
  echo

  for target in "$@"; do
    echo "## $target"

    #Strip protocol for DNS lookup if a URL was given
    host_part="$target"
    case "$host_part" in
      http://* | https://*)
        host_part="${host_part#http://}"
        host_part="${host_part#https://}"
        host_part="${host_part%%/*}"
        ;;
    esac

    echo "  Host part: $host_part"

    # DNS resolution
    ip_line="$(getent hosts "$host_part" || true)"
    if [ -z "$ip_line" ]; then
      echo " DNS:       FAILED (no A/AAAA record)"
      dns_ok=0
    else
      echo " DNS:       OK ($ip_line)"
      dns_ok=1
    fi

    # HTTP check only if DNS succeeded and looks like HTTP(S)
    http_status="N/A"
    http_ok=0

    case "$target" in
      http://* | https://*)
        if [ "$dns_ok" -eq 1 ]; then
          code="$(curl -sS -o /dev/null -w '%{http_code}' "$target" || echo "000")"
          http_status="$code"
          if [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
            http_ok=1
            echo "  HTTP:       OK (status $code)"
          else
            echo "  HTTP:       WARING/ERROR (status $code)"
          fi
        else
          echo "    HTTP:       SKIPPED (DNS failed)"
        fi
        ;;
      *)
        echo "  HTTP:       SKIPPED (not an HTTP/HTTPS URL)"
        ;;
    esac

    # Decide per-target status
    # CRITICAL if DNS failed or curl couldn't connect (code 000)
    # WARNING if DNS ok but HTTP non-2xx/3xx
    # OK if DNS ok and HTTP ok OR it's a non-HTTP target with DNS ok
    svc_status=0

    if [ "$dns_ok" -eq 0 ]; then
      svc_status=2
    else
      case "$target" in
        http://* | https://*)
          if [ "$http_ok" -eq 1 ]; then
            svc_status=0
          else
            if [ "$http_status" = "000" ]; then
              svc_status=2
            else
              svc_status=1
            fi
          fi
          ;;
        *)
          # Non-HTTP: only DNS matters
          svc_status=0
          ;;
      esac
    fi

    echo "  status: $svc_status"
    echo

    if [ "$svc_status" -gt "$overall" ]; then
      overall="$svc_status"
    fi
  done

  echo "Summary:"
  case "$overall" in
    0) echo "OVERALL: OK (all targets reachable / healthy enough)" ;;
    1) echo "OVERALL: WARNING (some targets reachable but with HTTP errors)" ;;
    2) echo "OVERALL: CRITICAL (one or more targets unreachable / DNS/TCP failures)" ;;
    *) echo "OVERALL: UNKNOWN (code ${overall})" ;;
  esac
} >"$OUT"

cat "$OUT"
echo "Saved to: $OUT"

exit "$overall"
