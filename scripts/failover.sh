#!/usr/bin/env bash
# failover.sh — demonstrate automatic failover by killing and reviving backends
#
# Watch this alongside Grafana → Load Distribution to see traffic
# automatically redistribute when a backend goes down.
#
# Usage: bash scripts/failover.sh [LB_URL]

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LB_URL="${1:-http://localhost:8080}"

BACKENDS=(
  "http://backend1:8001"
  "http://backend2:8002"
  "http://backend3:8003"
)

echo -e "${CYAN}${BOLD}golb — Failover Demo${NC}"
echo -e "Load Balancer: ${LB_URL}"
echo ""
echo -e "${YELLOW}Open Grafana → Load Distribution to watch traffic shift in real time.${NC}"
echo ""

# Keep firing requests in the background
echo -e "${GREEN}Starting background traffic (100 req/s)...${NC}"
( while true; do
    curl -sf "${LB_URL}" > /dev/null 2>&1 || true
    sleep 0.01
  done ) &
TRAFFIC_PID=$!

cleanup() {
  kill "$TRAFFIC_PID" 2>/dev/null || true
  # Revive all backends before exiting
  for b in "${BACKENDS[@]}"; do
    curl -sf -X POST "${LB_URL}/api/add?url=${b}" > /dev/null 2>&1 || true
  done
  echo -e "\n${GREEN}All backends restored. Traffic stopped.${NC}"
}
trap cleanup EXIT

sleep 3

for BACKEND in "${BACKENDS[@]}"; do
  echo ""
  echo -e "${RED}✗ Killing ${BACKEND}...${NC}"
  curl -sf -X POST "${LB_URL}/api/kill?url=${BACKEND}" > /dev/null

  echo "  Waiting 10s — watch Grafana Throughput panel..."
  sleep 10

  echo -e "${GREEN}✓ Reviving ${BACKEND}...${NC}"
  curl -sf -X POST "${LB_URL}/api/add?url=${BACKEND}" > /dev/null

  echo "  Waiting 8s for health checker to pick it up..."
  sleep 8
done

echo ""
echo -e "${GREEN}Failover demo complete!${NC}"
