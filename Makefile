.PHONY: help setup deps compile test format credo clean db-setup db-reset db-migrate server iex docker-build docker-up

help: ## Show this help
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Initial project setup
	@echo "🚀 Setting up YT Tracker..."
	mix deps.get
	mix ecto.setup
	@echo "✅ Setup complete!"

deps: ## Install dependencies
	mix deps.get

compile: ## Compile the project
	mix compile

test: ## Run tests
	mix test

test-watch: ## Run tests in watch mode
	mix test.watch

format: ## Format code
	mix format

credo: ## Run static code analysis
	mix credo --strict

clean: ## Clean build artifacts
	mix clean
	rm -rf _build deps

db-setup: ## Create and migrate database
	mix ecto.setup

db-reset: ## Drop, create, and migrate database
	mix ecto.reset

db-migrate: ## Run pending migrations
	mix ecto.migrate

db-rollback: ## Rollback last migration
	mix ecto.rollback

server: ## Start Phoenix server
	mix phx.server

iex: ## Start IEx with project loaded
	iex -S mix phx.server

docker-build: ## Build Docker image
	docker-compose build

docker-up: ## Start with Docker Compose
	docker-compose up

docker-down: ## Stop Docker Compose
	docker-compose down

release: ## Build production release
	MIX_ENV=prod mix release

.DEFAULT_GOAL := help
