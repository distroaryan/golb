#!/usr/bin/env bash
# loadtest.sh — run k6 load test against a running stack
#
# Usage:
#   bash scripts/loadtest.sh                        # default: http://localhost:8080
#   bash scripts/loadtest.sh http://myhost:8080     # custom target
#   LB_URL=http://myhost:8080 bash scripts/loadtest.sh

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LB_URL="${1:-${LB_URL:-http://localhost:8080}}"

echo -e "${CYAN}golb — k6 Load Test${NC}"
echo -e "Target: ${YELLOW}${LB_URL}${NC}"
echo ""

# Verify LB is reachable
echo -e "${GREEN}Checking target is reachable...${NC}"
if ! curl -sf "${LB_URL}/api/health" > /dev/null 2>&1; then
  echo -e "${RED}✗ Cannot reach ${LB_URL}/api/health${NC}"
  echo "  Start the stack first: bash scripts/up.sh"
  exit 1
fi
echo -e "${GREEN}✓ Target is healthy${NC}"
echo ""

echo -e "${GREEN}Running k6 load test...${NC}"
echo "  Stages: ramp 30s → sustain 60s → ramp down 30s → cool 20s"
echo "  SLOs:   p95 < 500ms  |  p99 < 1000ms  |  errors < 1%"
echo ""

k6 run -e LB_URL="${LB_URL}" k6/loadtest.js
