#!/usr/bin/env bash
# up.sh — start the full golb stack (load balancer + backends + prometheus + grafana)
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}golb — Starting stack...${NC}"
docker compose up -d --build

echo ""
echo -e "${GREEN}All services started:${NC}"
echo "  🔀  Load Balancer → http://localhost:8080"
echo "  📊  Prometheus    → http://localhost:9090"
echo "  📈  Grafana       → http://localhost:3000  (admin / admin)"
echo ""
echo "  Check health:  bash scripts/health.sh"
echo "  Run load test: bash scripts/loadtest.sh"
echo "  Tear down:     bash scripts/teardown.sh"
