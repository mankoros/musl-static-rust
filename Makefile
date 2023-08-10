.PONHY: help build install

TOOLCHAIN_IMG := rv-toolchain-builder
TOOLCHAIN_INSTALL := /opt/riscv

help:
	@echo "Usage: make [target]"
	@echo "  build: build docker image"
	@echo "  install: install toolchain to $(TOOLCHAIN_INSTALL)"

build:
	docker build --network host -t $(TOOLCHAIN_IMG) -f docker/Dockerfile.gcc docker

install:
ifeq ("$(wildcard $(TOOLCHAIN_INSTALL))","")
	make build
# remove the old container if exists
	docker rm -f $(TOOLCHAIN_IMG)-tmp || true
	docker create --name $(TOOLCHAIN_IMG)-tmp $(TOOLCHAIN_IMG)
	docker cp $(TOOLCHAIN_IMG)-tmp:/opt/riscv $(TOOLCHAIN_INSTALL)
	docker rm $(TOOLCHAIN_IMG)-tmp
endif