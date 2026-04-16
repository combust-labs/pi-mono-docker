# Makefile for building the Docker image

# Extract the PI_MONO_VERSION argument from Dockerfile (e.g., v0.67.5)
VERSION := $(shell grep -E '^ARG PI_MONO_VERSION=' Dockerfile | cut -d'=' -f2)

.PHONY: build-docker install-ppi
build-docker:
	@echo "Building Docker image with tag localhost/pi-mono:$(VERSION)"
	docker build --no-cache -t localhost/pi-mono:$(VERSION) .

install-ppi:
	@mkdir -p "$$HOME/.local/bin"
	@cp ppi "$$HOME/.local/bin/ppi"
	@chmod +x "$$HOME/.local/bin/ppi"
	@echo "Installed ppi to $$HOME/.local/bin/ppi"
	@echo "Add $$HOME/.local/bin to your PATH, e.g., export PATH=\"$$HOME/.local/bin:\$PATH\""

