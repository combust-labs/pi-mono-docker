# Makefile for building the Docker image

# Extract the PI_MONO_VERSION argument from Dockerfile (e.g., v0.67.5)
VERSION := $(shell grep -E '^ARG PI_MONO_VERSION=' Dockerfile | cut -d'=' -f2)

.PHONY: build-docker
build-docker:
	@echo "Building Docker image with tag localhost/pi-mono:$(VERSION)"
	docker build --no-cache -t localhost/pi-mono:$(VERSION) .
