# ============================================================
# Project Makefile — targets referenced by CLAUDE.md & hooks
# Customize commands for your build system as needed.
# ============================================================

.PHONY: help build lint test test-unit test-integration test-e2e test-e2e-headed test-e2e-trace test-smoke test-perf ci deploy-staging deploy-production

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---- Build ----

build: ## Install dependencies
	pip install -e ".[dev]"

# ---- Lint & Type Check ----

lint: ## Run ruff + mypy
	ruff check src/ tests/
	ruff format --check src/ tests/
	mypy src/

format: ## Auto-fix lint issues
	ruff check --fix src/ tests/
	ruff format src/ tests/

# ---- Tests ----

test-unit: ## Run unit tests (fast, mocked)
	pytest tests/unit/ -m unit --cov=src --cov-report=term-missing

test-integration: ## Run integration tests (real components)
	pytest tests/integration/ -m integration

test-e2e: ## Run end-to-end tests (deployed service, Playwright)
	pytest tests/e2e/ -m e2e

test-e2e-headed: ## Run E2E tests with visible browser
	pytest tests/e2e/ -m e2e --headed

test-e2e-trace: ## Run E2E tests with trace recording
	pytest tests/e2e/ -m e2e --tracing on

test-smoke: ## Run smoke tests (health checks)
	pytest tests/smoke/ -m smoke

test-perf: ## Run performance tests (load/stress)
	pytest tests/perf/ -m perf

test: test-unit test-integration ## Run unit + integration (default CI suite)

# ---- CI ----

ci: lint test ## Full CI: lint + typecheck + tests (used by pre-commit hook)

# ---- Deploy ----

deploy-staging: ## Deploy to Azure App Service staging slot
	@echo "Configure your Azure deployment command here"
	@echo "Example: az webapp config container set --name \$$SERVICE --slot staging --image \$$IMAGE_TAG ..."

deploy-production: ## Swap staging to production (zero downtime)
	@echo "Configure your Azure deployment command here"
	@echo "Example: az webapp deployment slot swap --name \$$SERVICE --slot staging --target-slot production"
