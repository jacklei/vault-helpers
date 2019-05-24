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
		--enable \
		--configure 

newapp: ## Everything that you need to do for a new namespace
	configure/kubernetes.sh \
		--context kubes-stage-la
	# create kubernetes namespace with vault service token
	configure/kubernetes.sh \
		--new-namespace demo
	# add new policies if any, we'll just use the one from make policy
	# attach role to k8s auth
	configure/vault-auth-kubernetes.sh \
		--names vault \
		--namespaces demo \
		--policies demo-db-r \
		--role demo
	# kubectl -n demo run -it --rm --image=alpine --serviceaccount=vault test -- /bin/sh
	# 
	# curl --request POST --data '{"jwt": "$JWT", "role": "demo"}' -k https://vault.stage.opcon.dev:8200/v1/auth/kubernetes/login


# ------------------------ 'make all' ends here ------------------------------#

print-%  : ## Print any variable from the Makefile (e.g. make print-VARIABLE);
	@echo $* = $($*)

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
