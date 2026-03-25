#!/usr/bin/env bash
# health.sh — display live health status of all backends
#
# Usage:
#   bash scripts/health.sh
#   bash scripts/health.sh http://myhost:8080

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LB_URL="${1:-http://localhost:8080}"

echo -e "${CYAN}${BOLD}golb — Backend Health Status${NC}"
echo -e "Load Balancer: ${LB_URL}"
echo ""

RESPONSE=$(curl -sf "${LB_URL}/api/health" 2>/dev/null || echo "ERR")

if [ "$RESPONSE" = "ERR" ]; then
  echo -e "${RED}✗ Cannot connect to load balancer at ${LB_URL}${NC}"
  echo "  Start the stack: bash scripts/up.sh"
  exit 1
fi

echo -e "${BOLD}SERVER                          STATUS${NC}"
echo "------                          ------"

echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for server, healthy in sorted(data.items()):
    status = '\033[92m✅ Healthy\033[0m' if healthy else '\033[91m❌ Dead\033[0m'
    print(f'  {server:<35} {status}')
" 2>/dev/null || {
  # Fallback if python3 not available — raw output
  echo "$RESPONSE"
}

echo ""
# also hit prometheus for a live RPS
RPS=$(curl -sf "http://localhost:9090/api/v1/query?query=sum(rate(golb_requests_total%5B1m%5D))" 2>/dev/null \
  | python3 -c "import json,sys; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]):.2f}\" if r else '0')" 2>/dev/null || echo "n/a")
echo -e "  Current RPS (1m avg): ${CYAN}${BOLD}${RPS} req/s${NC}"
