.PHONY: install build test test-unit test-integration test-e2e lint format ci run docker-run

# ──────────────────────────────────────────────
# Development
# ──────────────────────────────────────────────

install:
	pip install -r requirements-dev.txt

format:
	ruff format src/ tests/

lint:
	ruff check src/ tests/
	mypy src/ --ignore-missing-imports

run:
	python -m src $(TOPIC) $(ARGS)

# ──────────────────────────────────────────────
# Testing
# ──────────────────────────────────────────────

test-unit:
	pytest tests/unit/ -m unit -v --tb=short

test-integration:
	pytest tests/integration/ -m integration -v --tb=short

test-e2e:
	pytest tests/e2e/ -m e2e -v --tb=short

test: test-unit test-integration

# ──────────────────────────────────────────────
# CI (runs everything)
# ──────────────────────────────────────────────

ci: lint test
	pytest tests/unit/ tests/integration/ -m "unit or integration" --cov=src --cov-report=term-missing --cov-fail-under=80

# ──────────────────────────────────────────────
# Build & Deploy
# ──────────────────────────────────────────────

build:
	docker build -t deep-research-agent-v2:latest .

docker-run:
	docker run --env-file .env deep-research-agent-v2:latest $(TOPIC) $(ARGS)
