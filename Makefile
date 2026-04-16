# SPDX-License-Identifier: Apache-2.0
# Makefile for building the Docker image

# Help target
help:
	@echo "Available make targets:"
	@grep -E '^[a-zA-Z0-9_-]+:' $(MAKEFILE_LIST) | grep -v '^\.PHONY' | cut -d: -f1 | sort

# Extract the PI_MONO_VERSION argument from Containerfile (e.g., v0.67.5)
VERSION := $(shell grep -E '^ARG PI_MONO_VERSION=' container/Containerfile | cut -d'=' -f2)

.PHONY: build-docker install-ppi
build-docker:
	@echo "Building Docker image with tag localhost/pi-mono:$(VERSION)"
	@cd container && docker build --no-cache -f Containerfile -t localhost/pi-mono:$(VERSION) .

install-ppi:
	@mkdir -p "$$HOME/.local/bin"
	@cp ppi "$$HOME/.local/bin/ppi"
	@chmod +x "$$HOME/.local/bin/ppi"
	@echo "Installed ppi to $$HOME/.local/bin/ppi"
	@echo "Add $$HOME/.local/bin to your PATH, e.g., export PATH=\"$$HOME/.local/bin:$$PATH\""

hf-push-sessions:
	@[ -d ./.pi/sessions/--code--/ ] && hf upload rgruchalski/combust-labs_pi-mono-docker ./.pi/sessions/--code--/ --repo-type=dataset

