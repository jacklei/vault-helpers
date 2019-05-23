#!/usr/bin/env make

db: ## Configure secrets engine for database
	# database host is on private network
	configure/vault-secrets-database.sh \
		--db-name demo2 \
		--host demo2db.stage.opcon.dev:3306 \
		--username root \
		--password cloudnext \
		--role-name demo-app \
		--enable \
		--configure \
		--role



print-%  : ## Print any variable from the Makefile (e.g. make print-VARIABLE);
	@echo $* = $($*)

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
