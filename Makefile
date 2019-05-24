#!/usr/bin/env make

all: setup port-forward db policy auth-k8s

setup: ## Setup Kubernetes: token reviewer, rcb, config map, vault tls
	configure/kubernetes.sh \
		--context kubes-stage-la \
		--vault-addr https://vault.stage.opcon.dev:8200 \
		--vault-cacert $$VAULT_CACERT \
		--setup

port-forward: ## port forward vault to 127.0.0.1
	configure/kubernetes.sh \
		--context common-stage \
		--port-forward vault 8200

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
		--roatate-root \
		--role

policy: ## Configure vault policy
	configure/vault-general.sh \
		--policy demo-db-r.hcl

auth-k8s: ## Configure auth method for kubernetes
	# ensure we're on the correct context
	configure/kubernetes.sh \
		--context kubes-stage-la

	configure/vault-auth-kubernetes.sh \
		--token-reviewer-jwt $$(configure/kubernetes.sh --token-reviewer-jwt) \
		--k8s-host $$(configure/kubernetes.sh --k8s-host) \
		--k8s-cacert-base64 $$(configure/kubernetes.sh --k8s-cacert) \
		--role-name demo \
		--policies demo \
		--enable \
		--configure \
		--role



# ------------------------ 'make all' ends here ------------------------------#

print-%  : ## Print any variable from the Makefile (e.g. make print-VARIABLE);
	@echo $* = $($*)

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
