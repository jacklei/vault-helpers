#!/usr/bin/env make

all: setup port-forward db  auth-k8s 

setup: ## Setup Kubernetes: token reviewer, rcb, config map, vault tls
	configure/kubernetes.sh \
		--context kubes-stage-la \
		--setup

port-forward: ## port forward vault to 127.0.0.1
	configure/kubernetes.sh \
		--context common-stage \
		--port-forward vault 8200

db: ## enable secrets engine for database
	configure/vault-secrets-database.sh --enable 

auth-k8s: ## Configure auth method for kubernetes
	# ensure we're on the correct context
	configure/kubernetes.sh \
		--context kubes-stage-la

	configure/vault-auth-kubernetes.sh \
		--token-reviewer-jwt $$(configure/kubernetes.sh --token-reviewer-jwt) \
		--k8s-host $$(configure/kubernetes.sh --k8s-host) \
		--k8s-cacert-base64 $$(configure/kubernetes.sh --k8s-cacert) \
		--enable \
		--configure 

newapp: ## Everything that you need to do for a new app
	# create kubernetes namespace with vault service token
	configure/kubernetes.sh \
		--context kubes-stage-la \
		--vault-addr https://vault.stage.opcon.dev:8200 \
		--vault-cacert $$VAULT_CACERT \
		--new-namespace demo

	# 1. configure new db connection
	# database/config/demo-db-name
	# demo2: database name
	# 2. add role for generating dynamic secrets
	# database/roles/demo-role
	# demo-app: role that can generate passwords
	configure/vault-secrets-database.sh \
		--db-name demo-db-name \
		--host demo2db.stage.opcon.dev:3306 \
		--username root \
		--password cloudnext \
		--role-name demo-role \
		--configure \
		--role

	# add policy
	# database/creds/$namespace-role
	# creds: for dynamic secrets
	# demo-app: the db role that can generate passwords
	configure/vault-general.sh --policy demo-db-r

	# attach role to k8s auth (demo is a k8s auth role)
	# auth/kubernetes/role/demo
	# demo: k8s role that is associated to the policy
	# demo-db-r: policy name
	configure/vault-auth-kubernetes.sh \
		--names vault \
		--namespaces demo \
		--policies demo-db-r \
		--role demo


# ------------------------ 'make all' ends here ------------------------------#

print-%  : ## Print any variable from the Makefile (e.g. make print-VARIABLE);
	@echo $* = $($*)

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
