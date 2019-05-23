#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

AUTH_PATH=
TOKEN_REVIEWER_JWT=
KUBERNETES_HOST=
KUBERNETES_CACERT=
ROLE_NAME=
SERVICE_ACCOUNT_NAMES=
SERVICE_ACCOUNT_NAMESPACES=
POLICIES=
TTL=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function enable() {
    vault auth enable ${AUTH_PATH:+"-path=$AUTH_PATH"} kubernetes
}

function configure() {
    : ${TOKEN_REVIEWER_JWT:?configure requires TOKEN_REVIEWER_JWT to be set, --token-reviewer-jwt jwt}
    : ${KUBERNETES_HOST:?configure requires KUBERNETES_HOST to be set, --k8s-host host}

    vault write auth/${AUTH_PATH:-kubernetes}/config \
        token_reviewer_jwt="${TOKEN_REVIEWER_JWT}" \
        kubernetes_host=${KUBERNETES_HOST} \
        kubernetes_ca_cert=${KUBERNETES_CACERT:-@ca.crt}
}

function role() {
    : ${ROLE_NAME:?role requires ROLE_NAME to be set, --role-name role_name}

    vault write auth/${AUTH_PATH:-kubernetes}/role/${ROLE_NAME} \
        bound_service_account_names=${SERVICE_ACCOUNT_NAMES:-vault-auth} \
        bound_service_account_namespaces=${SERVICE_ACCOUNT_NAMESPACES:-default} \
        policies=${POLICIES:-default} \
        ttl=${TTL:-1h}
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
while true; do
  case "$1" in
    --auth-path ) AUTH_PATH=$2; shift 2;;
    -j | --token-reviewer-jwt ) TOKEN_REVIEWER_JWT=$2; shift 2;;
    -h | --k8s-host ) KUBERNETES_HOST=$2; shift 2;;
    -c | --k8s-cacert ) KUBERNETES_CACERT=$2; shift 2;;
    -rn | --role-name ) ROLE_NAME=$2; shift 2;;
    -n | --names ) SERVICE_ACCOUNT_NAMES=$2; shift 2;;
    -ns | --namespaces ) SERVICE_ACCOUNT_NAMESPACES=$2; shift 2;;
    -p | --policies ) POLICIES=$2; shift 2;;
    -t | --ttl ) TTL=$2; shift 2;;

    -e | --enable ) enable; shift;;
    -c | --configure ) configure; shift;;
    -r | --role ) role; shift;;

    -- ) shift; break ;;
    * ) break ;;
  esac
done