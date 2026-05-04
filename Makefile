# SPDX-License-Identifier: Apache-2.0
# Makefile for building the Docker image

# Help target
help:
	@echo "Available make targets:"
	@grep -E '^[a-zA-Z0-9_-]+:' $(MAKEFILE_LIST) | grep -v '^\.PHONY' | cut -d: -f1 | sort

# Extract the PI_MONO_VERSION argument from Containerfile
VERSION := $(shell grep -E '^ARG PI_MONO_VERSION=' container/Containerfile | cut -d'=' -f2)

# Extract the PI_MONO_GIT_REPO argument from Containerfile
PI_MONO_GIT_REPO := $(shell grep -E '^ARG PI_MONO_GIT_REPO=' container/Containerfile | cut -d'=' -f2)

# Extensions to install (comma-separated list, e.g., "read-website,subagent")
PI_MONO_EXTENSIONS ?= ""

.PHONY: build-docker install-ppi check-update hf-push-sessions
build-docker:
	@echo "Building Docker image with tag localhost/pi-mono:$(VERSION)"
	@echo "Extensions: $(PI_MONO_EXTENSIONS)"
	@cd container && docker build --no-cache -f Containerfile \
		--build-arg PI_MONO_VERSION=$(VERSION) \
		--build-arg PI_MONO_GIT_REPO=$(PI_MONO_GIT_REPO) \
		--build-arg PI_MONO_EXTENSIONS=$(PI_MONO_EXTENSIONS) \
		-t localhost/pi-mono:$(VERSION) .

install-ppi:
	@mkdir -p "$$HOME/.local/bin"
	@cp ppi "$$HOME/.local/bin/ppi"
	@chmod +x "$$HOME/.local/bin/ppi"
	@echo "Installed ppi to $$HOME/.local/bin/ppi"
	@echo "Add $$HOME/.local/bin to your PATH, e.g., export PATH=\"$$HOME/.local/bin:$$PATH\""

hf-push-sessions:
	@[ -d ./.pi/sessions/--code--/ ] && hf upload rgruchalski/combust-labs_pi-mono-docker ./.pi/sessions/--code--/ --repo-type=dataset

# Check for pi-mono updates via GitHub API
check-update:
	@echo "Current version: $(VERSION)"
	@echo "Fetching latest release from GitHub..."
	@echo "Repository: $(PI_MONO_GIT_REPO)"
	@REPO=$$(echo $(PI_MONO_GIT_REPO) | sed -E 's|.*github.com/||' ); REPO=$${REPO%.git}; \
	LATEST=$$(curl -s https://api.github.com/repos/$$REPO/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'); \
	if [ -z "$$LATEST" ]; then \
		echo "Error: Could not fetch latest release. Check your internet connection."; \
		exit 1; \
	fi; \
	echo "Latest version: $$LATEST"; \
	if [ "$(VERSION)" = "$$LATEST" ]; then \
		echo "✓ You are running the latest version!"; \
	else \
		echo "⚠ Update available: $(VERSION) → $$LATEST"; \
		echo "  Run 'sed -i "s/ARG PI_MONO_VERSION=.*/ARG PI_MONO_VERSION=$$LATEST/" container/Containerfile' to update."; \
	fi

