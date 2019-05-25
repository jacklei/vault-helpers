#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

auth_path=
token_reviewer_jwt=
kubernetes_host=
kubernetes_cacert=
kubernetes_cacert_base64=
role_name=
service_account_names=
service_account_namespaces=
policies=
ttl=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
enable() {
    vault auth enable ${auth_path:+"-path=$auth_path"} kubernetes
}

configure() {
    : ${token_reviewer_jwt:?configure requires token_reviewer_jwt to be set, --token-reviewer-jwt jwt}
    : ${kubernetes_host:?configure requires kubernetes_host to be set, --k8s-host host}

    # base64 decode kubernetes ca cert
    if [[ -n kubernetes_cacert_base64 && -n kubernetes_cacert ]]; then
        kubernetes_cacert=$(echo "${kubernetes_cacert}" | base64 --decode)
    fi

    vault write auth/${auth_path:-kubernetes}/config \
        token_reviewer_jwt="${token_reviewer_jwt}" \
        kubernetes_host="${kubernetes_host}" \
        kubernetes_ca_cert="${kubernetes_cacert:-@ca.crt}"
}

role() {
    : ${role_name:?role requires role_name to be set, --role-name role_name}

    vault write auth/${auth_path:-kubernetes}/role/${role_name} \
        bound_service_account_names=${service_account_names:-vault} \
        bound_service_account_namespaces=${service_account_namespaces:-default} \
        policies=${policies:-default} \
        ttl=${ttl:-1h}
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
while true; do
  case "$1" in
    --auth-path ) auth_path=$2; shift 2;;
    -j | --token-reviewer-jwt ) token_reviewer_jwt=$2; shift 2;;
    -h | --k8s-host ) kubernetes_host=$2; shift 2;;
    -c | --k8s-cacert ) kubernetes_cacert=$2; shift 2;;
    -c64 | --k8s-cacert-base64 ) 
        kubernetes_cacert=$2; 
        kubernetes_cacert_base64=true;
        shift 2;;
    -n | --names ) service_account_names=$2; shift 2;;
    -ns | --namespaces ) service_account_namespaces=$2; shift 2;;
    -p | --policies ) policies=$2; shift 2;;
    -t | --ttl ) ttl=$2; shift 2;;

    -e | --enable ) enable; shift;;
    -c | --configure ) configure; shift;;
    -r | --role ) 
        role_name=$2;
        role; 
        shift 2;;

    -- ) shift; break ;;
    * ) break ;;
  esac
done