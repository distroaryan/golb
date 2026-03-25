#!/usr/bin/env bash
# demo.sh — full demo: start stack → wait for health → run k6 → tail status
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
 _                     _           
| |                   | |          
| |     ___   __ _  __| | _____  __
| |    / _ \ / _` |/ _` |/ _ \ \/ /
| |___| (_) | (_| | (_| |  __/>  < 
\____/ \___/ \__,_|\__,_|\___/_/\_\

  golb — Full Demo
EOF
echo -e "${NC}"

# ── 1. Start stack ──────────────────────────────────────────────────────────
echo -e "${GREEN}[1/3] Starting services...${NC}"
docker compose up -d --build

# ── 2. Wait for load balancer ───────────────────────────────────────────────
echo -e "${GREEN}[2/3] Waiting for load balancer to be ready...${NC}"
for i in $(seq 1 30); do
  status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/health 2>/dev/null || echo "000")
  if [ "$status" = "200" ]; then
    echo -e "  ${GREEN}✓ Load balancer is ready${NC}"
    break
  fi
  echo "  Retrying... (${i}/30)"
  sleep 1
done

echo ""
echo -e "${CYAN}  Services:${NC}"
echo "  🔀  Load Balancer → http://localhost:8080"
echo "  📊  Prometheus    → http://localhost:9090"
echo "  📈  Grafana       → http://localhost:3000  (admin / admin)"
echo ""
echo -e "${YELLOW}  ▶  Open Grafana → Dashboards → Golb Load Balancer now${NC}"
echo ""

# ── 3. Run k6 ───────────────────────────────────────────────────────────────
echo -e "${GREEN}[3/3] Running k6 load test (~2m 20s)...${NC}"
echo "  ramp: 0 → 20 → 50 VUs → 20 → 0"
echo ""

k6 run k6/loadtest.js

echo ""
echo -e "${GREEN}Demo complete!${NC}  Stop everything: bash scripts/teardown.sh"
