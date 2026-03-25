#!/usr/bin/env bash
# teardown.sh — stop the stack and clean up
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}golb — Tearing down stack...${NC}"

docker compose down

echo ""
echo -e "${GREEN}✓ All containers stopped and removed${NC}"

# Optional: remove built binaries
if [ "${1}" = "--clean" ]; then
  echo -e "${YELLOW}Removing built binaries...${NC}"
  rm -rf bin/
  echo -e "${GREEN}✓ bin/ removed${NC}"
fi

echo ""
echo "  Restart with: bash scripts/up.sh"
