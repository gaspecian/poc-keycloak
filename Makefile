.PHONY: help install start stop restart clean logs status configure

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m

help: ## Show this help message
	@echo "$(GREEN)POC: Keycloak as IDP for APIs$(NC)"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

install: ## Install all dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	cd apps/todo-backend && dotnet restore
	cd apps/todo-frontend && npm install --legacy-peer-deps
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

start: ## Start all services (infrastructure + backend + frontend)
	@echo "$(GREEN)Starting infrastructure...$(NC)"
	cd keycloak && docker compose up -d
	@echo "$(YELLOW)Waiting for Keycloak to be ready (30s)...$(NC)"
	@sleep 30
	@echo "$(GREEN)Starting backend API...$(NC)"
	cd apps/todo-backend && dotnet run &
	@sleep 5
	@echo "$(GREEN)Starting frontend...$(NC)"
	cd apps/todo-frontend && npm run dev &
	@echo "$(GREEN)✅ All services started!$(NC)"
	@echo ""
	@echo "Services:"
	@echo "  - Keycloak:  http://localhost:8080"
	@echo "  - Backend:   http://localhost:5001"
	@echo "  - Frontend:  http://localhost:3000"

start-infra: ## Start only infrastructure (Keycloak + PostgreSQL)
	@echo "$(GREEN)Starting infrastructure...$(NC)"
	cd keycloak && docker compose up -d
	@echo "$(GREEN)✅ Infrastructure started$(NC)"

start-backend: ## Start only backend API
	@echo "$(GREEN)Starting backend API...$(NC)"
	cd apps/todo-backend && dotnet run

start-frontend: ## Start only frontend
	@echo "$(GREEN)Starting frontend...$(NC)"
	cd apps/todo-frontend && npm run dev

stop: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(NC)"
	pkill -f "dotnet run" || true
	pkill -f "next dev" || true
	cd keycloak && docker compose down
	@echo "$(GREEN)✅ All services stopped$(NC)"

stop-infra: ## Stop only infrastructure
	@echo "$(YELLOW)Stopping infrastructure...$(NC)"
	cd keycloak && docker compose down
	@echo "$(GREEN)✅ Infrastructure stopped$(NC)"

restart: stop start ## Restart all services

clean: stop ## Stop services and remove all data
	@echo "$(YELLOW)Removing all data...$(NC)"
	cd keycloak && docker compose down -v
	@echo "$(GREEN)✅ All data removed$(NC)"

configure: ## Configure Keycloak (realm, clients, roles, groups)
	@echo "$(GREEN)Configuring Keycloak...$(NC)"
	cd keycloak && ./configure-keycloak.sh
	cd keycloak && ./configure-group-rbac.sh
	cd keycloak && ./add-app-access-role.sh
	@echo "$(GREEN)✅ Keycloak configured$(NC)"
	@echo ""
	@echo "Test credentials:"
	@echo "  Username: testuser"
	@echo "  Password: Test123!"

logs: ## Show logs from all services
	@echo "$(GREEN)Docker logs:$(NC)"
	cd keycloak && docker compose logs -f

logs-backend: ## Show backend logs
	@echo "$(GREEN)Backend logs:$(NC)"
	cd apps/todo-backend && dotnet run

logs-frontend: ## Show frontend logs
	@echo "$(GREEN)Frontend logs:$(NC)"
	cd apps/todo-frontend && npm run dev

status: ## Check status of all services
	@echo "$(GREEN)Service Status:$(NC)"
	@echo ""
	@echo "$(YELLOW)Infrastructure:$(NC)"
	@cd keycloak && docker compose ps
	@echo ""
	@echo "$(YELLOW)Backend API:$(NC)"
	@curl -s http://localhost:5001/health > /dev/null && echo "  ✅ Running" || echo "  ❌ Not running"
	@echo ""
	@echo "$(YELLOW)Frontend:$(NC)"
	@curl -s http://localhost:3000 > /dev/null && echo "  ✅ Running" || echo "  ❌ Not running"
	@echo ""
	@echo "$(YELLOW)Keycloak:$(NC)"
	@curl -s http://localhost:8080 > /dev/null && echo "  ✅ Running" || echo "  ❌ Not running"

setup: install start-infra configure ## Full setup (install + start infra + configure)
	@echo ""
	@echo "$(GREEN)✅ Setup complete!$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Start backend:  make start-backend"
	@echo "  2. Start frontend: make start-frontend"
	@echo "  3. Open browser:   http://localhost:3000"

dev: ## Start development environment (all services)
	@$(MAKE) start

test-api: ## Test API with curl
	@echo "$(GREEN)Testing API...$(NC)"
	@echo ""
	@echo "Getting token..."
	@TOKEN=$$(curl -s -X POST http://localhost:5001/api/auth/token \
		-H "Content-Type: application/json" \
		-d '{"grant_type":"password","client_id":"todo-backend-client","client_secret":"6pgXtE2psQJeS76QL91Ap4b0b4TUTnsN","username":"testuser","password":"Test123!"}' \
		| jq -r '.access_token') && \
	echo "✅ Token obtained" && \
	echo "" && \
	echo "Fetching todos..." && \
	curl -s http://localhost:5001/api/todos \
		-H "Authorization: Bearer $$TOKEN" | jq '.'

docker-build-backend: ## Build backend Docker image
	@echo "$(GREEN)Building backend Docker image...$(NC)"
	cd apps/todo-backend && docker build -t todo-backend .
	@echo "$(GREEN)✅ Backend image built$(NC)"

docker-build-frontend: ## Build frontend Docker image
	@echo "$(GREEN)Building frontend Docker image...$(NC)"
	cd apps/todo-frontend && docker build -t todo-frontend .
	@echo "$(GREEN)✅ Frontend image built$(NC)"

docker-build: docker-build-backend docker-build-frontend ## Build all Docker images

docker-run-backend: ## Run backend in Docker
	@echo "$(GREEN)Running backend in Docker...$(NC)"
	docker run -d --name todo-backend --network host todo-backend
	@echo "$(GREEN)✅ Backend running at http://localhost:5001$(NC)"

docker-run-frontend: ## Run frontend in Docker
	@echo "$(GREEN)Running frontend in Docker...$(NC)"
	docker run -d --name todo-frontend -p 3000:3000 \
		-e AUTH_SECRET=$$(openssl rand -base64 32) \
		todo-frontend
	@echo "$(GREEN)✅ Frontend running at http://localhost:3000$(NC)"

docker-run: docker-run-backend docker-run-frontend ## Run all apps in Docker

docker-stop: ## Stop Docker containers
	@echo "$(YELLOW)Stopping Docker containers...$(NC)"
	docker stop todo-backend todo-frontend 2>/dev/null || true
	docker rm todo-backend todo-frontend 2>/dev/null || true
	@echo "$(GREEN)✅ Containers stopped$(NC)"

docker-start: start-infra docker-build docker-run ## Start everything with Docker
