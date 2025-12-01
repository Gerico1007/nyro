# G.Music Assembly - Docker Compose Orchestration
# ♠️🌿🎸🧵 Terminal Integration Makefile

.PHONY: help build init up down shell clean status logs

# Default target
help: ## Show this help message
	@echo "🎼 G.Music Assembly - Docker Compose Orchestration"
	@echo "♠️🌿🎸🧵 Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the development environment
	@echo "🏗️  Building G.Music Assembly environment..."
	docker compose build

init: ## Initialize workspace with all repositories
	@echo "🚀 Initializing repositories..."
	docker compose run --rm dev /usr/local/bin/init-repos.sh

up: ## Start all services in background
	@echo "🎵 Starting orchestration..."
	docker compose up -d

down: ## Stop all services
	@echo "🛑 Stopping orchestration..."
	docker compose down

shell: ## Open interactive shell in dev container
	@echo "🐚 Opening development shell..."
	docker compose run --rm dev /bin/bash

status: ## Show container status
	@echo "📊 Container Status:"
	docker compose ps

logs: ## Show logs from all services
	@echo "📜 Service Logs:"
	docker compose logs -f

clean: ## Clean up containers and volumes
	@echo "🧹 Cleaning up..."
	docker compose down -v
	docker system prune -f

# Repository-specific shells
shell-echonexus: ## Open shell in EchoNexus repository
	docker compose run --rm echonexus /bin/bash

shell-orpheus: ## Open shell in Orpheus repository
	docker compose run --rm orpheus /bin/bash

shell-edgehub: ## Open shell in EdgeHub repository
	docker compose run --rm edgehub /bin/bash

shell-echothreads: ## Open shell in EchoThreads repository
	docker compose run --rm echothreads /bin/bash

shell-ea: ## Open shell in EA repository
	docker compose run --rm ea /bin/bash

shell-creersaviehelper: ## Open shell in CreerSaVieHelper repository
	docker compose run --rm creersaviehelper /bin/bash

shell-whitefeathers: ## Open shell in WhiteFeathers repository
	docker compose run --rm whitefeathers /bin/bash

shell-tushell: ## Open shell in tushell repository
	docker compose run --rm tushell /bin/bash

shell-nyro: ## Open shell in Nyro repository
	docker compose run --rm nyro /bin/bash

shell-jamai-core: ## Open shell in Jamai-core repository
	docker compose run --rm jamai-core /bin/bash

shell-nyroportal: ## Open shell in NyroPortal repository
	docker compose run --rm nyroportal /bin/bash

shell-sharedspark: ## Open shell in SharedSpark repository
	docker compose run --rm sharedspark /bin/bash

# Profile-based operations
start-all: ## Start all repository services
	docker compose --profile all up -d

start-python: ## Start Python-focused repositories
	docker compose --profile echonexus --profile orpheus --profile ea --profile nyro up -d

validate: ## Validate Docker Compose configuration
	@echo "✅ Validating Docker Compose configuration..."
	docker compose config

# Development workflows
dev-setup: build init ## Complete development setup (build + init)
	@echo "🎼 G.Music Assembly development environment ready!"

workspace-backup: ## Create backup of workspace
	@echo "💾 Creating workspace backup..."
	tar -czf workspace-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz workspace/

# Assembly-specific commands
assembly-status: ## Show Assembly-specific status
	@echo "♠️🌿🎸🧵 G.Music Assembly Status"
	@echo "Workspace: $(shell pwd)/workspace"
	@echo "Repositories: $(shell ls -1 workspace/ 2>/dev/null | wc -l || echo 0)"
	@echo "Active containers: $(shell docker compose ps -q | wc -l)"
	@make status

# Validation and testing
test: ## Run complete validation suite
	@echo "🧪 Running G.Music Assembly validation suite..."
	@./scripts/validate-setup.sh

validate-config: ## Validate Docker Compose configuration only
	@echo "✅ Validating Docker Compose configuration..."
	@docker compose config --quiet && echo "Configuration valid!"

validate-security: ## Run security validation checks
	@echo "🔒 Running security validation..."
	@echo "Checking for hardcoded secrets..."
	@! grep -r 'ghp_[0-9a-zA-Z]*' . --exclude-dir=.git --exclude='*.example' --exclude='SECURITY.md' --exclude-dir=scripts || echo "⚠️  Potential secrets found!"
	@echo "Checking file permissions..."
	@ls -la .env* 2>/dev/null || echo "No .env files found"
	@echo "Security validation complete!"