SHELL := /bin/bash
SCRIPTS := install.sh uninstall.sh bin/claude-tmux bin/claude-tmux-cleanup bin/claude-tmux-doctor scripts/ram.sh scripts/load.sh tests/smoke.sh

.PHONY: help install uninstall doctor check lint fmt fmt-check test

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Run the installer
	./install.sh

uninstall: ## Remove what the installer created
	./uninstall.sh

doctor: ## Verify the current machine's setup
	./bin/claude-tmux-doctor

check: lint fmt-check test ## Lint, format check and smoke tests

lint: ## Run shellcheck over every script
	shellcheck $(SCRIPTS)

fmt: ## Format every script with shfmt
	shfmt -w $(SCRIPTS)

fmt-check: ## Fail if any script is unformatted
	shfmt -d $(SCRIPTS)

test: ## Run the smoke tests
	./tests/smoke.sh
