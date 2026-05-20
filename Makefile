SHELL := /bin/bash

TF        ?= terraform
TFLINT    ?= tflint
TFSEC     ?= tfsec
DIRS      := modules/ecr modules/s3 environments/dev environments/local bootstrap

.PHONY: help fmt fmt-check validate lint sec all local-up local-down local-apply local-destroy

help:
	@echo "Targets:"
	@echo "  fmt           - terraform fmt -recursive (in place)"
	@echo "  fmt-check     - terraform fmt -check -recursive"
	@echo "  validate      - terraform validate in every module/env"
	@echo "  lint          - tflint --recursive"
	@echo "  sec           - tfsec ."
	@echo "  all           - fmt-check + validate + lint + sec"
	@echo "  local-up      - start LocalStack"
	@echo "  local-down    - stop LocalStack"
	@echo "  local-apply   - terraform apply against LocalStack"
	@echo "  local-destroy - terraform destroy against LocalStack"

fmt:
	$(TF) fmt -recursive

fmt-check:
	$(TF) fmt -check -recursive

validate:
	@set -e ; for d in $(DIRS) ; do \
		echo "--- $$d" ; \
		$(TF) -chdir=$$d init -backend=false -input=false >/dev/null ; \
		$(TF) -chdir=$$d validate ; \
	done

lint:
	$(TFLINT) --init >/dev/null
	$(TFLINT) --recursive

sec:
	$(TFSEC) .

all: fmt-check validate lint sec

local-up:
	docker compose up -d

local-down:
	docker compose down -v

local-apply:
	$(TF) -chdir=environments/local init
	$(TF) -chdir=environments/local apply -auto-approve

local-destroy:
	$(TF) -chdir=environments/local destroy -auto-approve
