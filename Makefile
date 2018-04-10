MAKEFILE_PATH:= $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_ROOT:= $(dir $(MAKEFILE_PATH))

TERRAFORM:=$(shell command -v terraform 2>/dev/null)
PRE_COMMIT:=$(shell command -v pre-commit 2>/dev/null)

ifndef TERRAFORM
$(error Terraform is not installed Please download and install Terraform first - https://www.terraform.io/downloads.html)
endif

ifndef PRE_COMMIT
$(error pre-commit is not installed. Please install pre-commit first - http://pre-commit.com/#install)
endif

.DEFAULT_GOAL := help
.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort -k2,2

.PHONY: dev-init
dev-init: ## Initiate development tools
	$(info ... pre-commit hooks installing)
	@$(PRE_COMMIT) install
	@$(TERRAFORM) init -backend=false -get=false -get-plugins=true
