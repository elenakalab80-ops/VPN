#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-elenakalab80-vpn-01}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

json_field() {
  # Usage: json_field '<json>' '<key>'
  python3 - "$1" "$2" <<'PY'
import json, sys
raw = sys.argv[1]
key = sys.argv[2]
try:
    obj = json.loads(raw)
    val = obj.get(key, "")
    if val is None:
        val = ""
    print(val)
except Exception:
    print("")
PY
}

ip_meta() {
  local ip="$1"
  local body city region country org tz
  body="$(curl -fsS "https://ipinfo.io/${ip}/json" 2>/dev/null || true)"
  city="$(json_field "$body" "city")"
  region="$(json_field "$body" "region")"
  country="$(json_field "$body" "country")"
  org="$(json_field "$body" "org")"
  tz="$(json_field "$body" "timezone")"
  echo "${country:-?} | ${region:-?} | ${city:-?} | ${org:-?} | ${tz:-?}"
}

need_cmd fly
need_cmd curl
need_cmd python3

echo "================ VPN STATUS ================"
echo "App: ${APP_NAME}"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

echo "---- Fly app status ----"
fly status -a "${APP_NAME}" || {
  echo "Cannot fetch Fly status for app: ${APP_NAME}"
  exit 1
}
echo

echo "---- Fly public IPs ----"
IPS_RAW="$(fly ips list -a "${APP_NAME}" 2>/dev/null || true)"
echo "${IPS_RAW}"
echo

PUBLIC_V4="$(echo "${IPS_RAW}" | awk 'NR>1 && $1=="v4" {print $2; exit}')"
if [[ -n "${PUBLIC_V4}" ]]; then
  echo "Server IPv4: ${PUBLIC_V4}"
  echo "Server geo:  $(ip_meta "${PUBLIC_V4}")"
  echo
  echo "---- Connectivity check (TCP 8388) ----"
  if nc -vz "${PUBLIC_V4}" 8388 >/dev/null 2>&1; then
    echo "TCP 8388 is reachable on ${PUBLIC_V4}"
  else
    echo "TCP 8388 is NOT reachable on ${PUBLIC_V4}"
  fi
  echo
else
  echo "No public IPv4 found. If needed: fly ips allocate-v4 -a ${APP_NAME}"
  echo
fi

echo "---- Your current public IP ----"
MY_IP="$(curl -fsS https://ifconfig.me 2>/dev/null || true)"
echo "Current IP: ${MY_IP:-unknown}"
if [[ -n "${MY_IP}" ]]; then
  echo "Current geo: $(ip_meta "${MY_IP}")"
fi
echo

echo "---- Last app logs (25 lines) ----"
fly logs -a "${APP_NAME}" --no-tail 2>/dev/null | tail -n 25 || true
echo
echo "Done."
