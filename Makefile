.PHONY: all build test clean build-backend build-lb build-cli demo k6 up down

# Binary names
BACKEND_BIN=backend.exe
LB_BIN=loadbalancer.exe
CLI_BIN=loadex.exe

# Build directory
BUILD_DIR=bin

all: clean build test

build: build-backend build-lb build-cli

build-backend:
	@echo "Building backend..."
	@go build -o $(BUILD_DIR)/$(BACKEND_BIN) ./cmd/backend

build-lb:
	@echo "Building loadbalancer..."
	@go build -o $(BUILD_DIR)/$(LB_BIN) ./cmd/loadbalancer

build-cli:
	@echo "Building loadex CLI..."
	@go build -o $(BUILD_DIR)/$(CLI_BIN) ./cmd/loadex

test:
	@echo "Running tests..."
	@go test -v ./...

clean:
	@echo "Cleaning up..."
	@rm -rf $(BUILD_DIR)
	@go clean

up:
	@docker compose up -d --build

down:
	@docker compose down

k6:
	@k6 run k6/loadtest.js

demo:
	@bash scripts/demo.sh

setup:
	@bash scripts/setup.sh

health:
	@bash scripts/health.sh

failover:
	@bash scripts/failover.sh

loadex:
	@./bin/loadex
