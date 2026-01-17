# ============================================================================
# OpenWatchParty - Makefile
# ============================================================================
# Usage: make [target]
# Run 'make help' for available targets
# ============================================================================

.DEFAULT_GOAL := help
SHELL := /bin/bash

# Include modular makefiles
include make/config.mk
include make/dev.mk
include make/build.mk
include make/test.mk
include make/docker.mk
include make/setup.mk
include make/utils.mk
include make/help.mk
