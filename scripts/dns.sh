#!/usr/bin/env sh
set -eu

API_BASE="https://desec.io/api/v1"

usage() {
  cat <<EOF
Usage: $(basename "$0") <domain> <ipv4> [ttl]

  <domain>  e.g. yourdomain.com
  <ipv4>    e.g. 203.0.113.1
  [ttl]     default: 3600

Env:
  DESEC_TOKEN  deSEC API token (required)
               Alternatively: export TOKEN=<token>

Examples:
  DESEC_TOKEN=xxx ./dns.sh yourdomain.com 203.0.113.1
  DESEC_TOKEN=xxx ./dns.sh yourdomain.com 203.0.113.1 3600

Docs:
  https://desec.readthedocs.io/en/latest/
EOF
}

TOKEN="${DESEC_TOKEN:-${TOKEN:-}}"
DOMAIN="${1:-}"
IP="${2:-}"
TTL="${3:-3600}"

if [ -z "$TOKEN" ] || [ -z "$DOMAIN" ] || [ -z "$IP" ]; then
  usage
  [ -z "$TOKEN" ] && echo "error: DESEC_TOKEN is not set" >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }

echo "Creating domain: $DOMAIN"
curl -fsS -X POST "$API_BASE/domains/" \
  --header "Authorization: Token $TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"name\": \"$DOMAIN\"}"
echo

echo "Creating apex A record: $DOMAIN -> $IP (ttl=$TTL)"
curl -fsS -X POST "$API_BASE/domains/$DOMAIN/rrsets/" \
  --header "Authorization: Token $TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"subname\": \"\", \"type\": \"A\", \"ttl\": $TTL, \"records\": [\"$IP\"]}"
echo

echo "Creating www A record: www.$DOMAIN -> $IP (ttl=$TTL)"
curl -fsS -X POST "$API_BASE/domains/$DOMAIN/rrsets/" \
  --header "Authorization: Token $TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"subname\": \"www\", \"type\": \"A\", \"ttl\": $TTL, \"records\": [\"$IP\"]}"
echo

echo "Done."
