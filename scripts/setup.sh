#!/usr/bin/env bash
# setup.sh — checks dependencies and builds all binaries
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
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

  golb — Setup
EOF
echo -e "${NC}"

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}✗ $1 is required but not installed.${NC}"
    echo "  Install: $2"
    exit 1
  else
    local version
    version=$($1 version 2>/dev/null | head -1 || $1 --version 2>/dev/null | head -1 || echo "found")
    echo -e "${GREEN}✓ $1${NC} — $version"
  fi
}

echo -e "${CYAN}Checking dependencies...${NC}"
check_cmd go      "https://go.dev/dl/"
check_cmd docker  "https://docs.docker.com/get-docker/"
check_cmd k6      "https://k6.io/docs/get-started/installation/"
echo ""

echo -e "${CYAN}Building binaries...${NC}"
mkdir -p bin
go build -o bin/backend      ./cmd/backend
go build -o bin/loadbalancer ./cmd/loadbalancer
go build -o bin/loadex       ./cmd/loadex
echo -e "${GREEN}✓ Built: bin/backend, bin/loadbalancer, bin/loadex${NC}"
echo ""

echo -e "${CYAN}Running unit tests...${NC}"
go test ./...
echo -e "${GREEN}✓ All tests passed${NC}"
echo ""

echo -e "${GREEN}Setup complete! Run the demo with:${NC}"
echo "  bash scripts/demo.sh"
