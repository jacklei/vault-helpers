#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

CONTEXT=
VAULT_ADDR=
NAMESPACE=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------

use_context() {
    kubectl config use-context ${CONTEXT:-minikube} &> /dev/null
}

setup() {
    # create service account to review tokens
    kubectl create serviceaccount vault-auth

    # give token reviewer access to service account
    kubectl apply \
        --filename=-<<EOH
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
EOH
    # Create a config map to store the vault address
    : ${VAULT_ADDR:?setup requires VAULT_ADDR to be set, --vault-addr https://vault_addr}
    kubectl create configmap vault \
        --from-literal "vault_addr=${VAULT_ADDR}"

    : ${VAULT_CACERT:?setup requires VAULT_CACERT to be set, --vault-cacert /tmp/ca.pem}
    # Create a secret for our CA
    kubectl create secret generic vault-tls \
        --from-file "${VAULT_CACERT}"

    }

get_token_reviewer_jwt() {
    # Get the name of the secret corresponding to the service account
    SECRET_NAME="$(kubectl get serviceaccount vault-auth \
        -o go-template='{{ (index .secrets 0).name }}')"

    # Get the actual token reviewer account
    TR_ACCOUNT_TOKEN="$(kubectl get secret ${SECRET_NAME} \
        -o go-template='{{ .data.token }}' | base64 --decode)"

    echo "${TR_ACCOUNT_TOKEN}"
}

get_k8s_host() {
    # found from https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#without-kubectl-proxy
    K8S_HOST="$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")"

    echo "${K8S_HOST}"
}

get_k8s_cacert() {
    # found from https://github.com/kubernetes/kubernetes/issues/61572
    K8S_CACERT="$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')"

    echo "${K8S_CACERT}"
}

port_forward() {
    APP="$1"
    PORT="$2"
    POD="$(kubectl get pod -l app="$APP" -o jsonpath='{.items[0].metadata.name}')"
    screen -dmS "$POD" /bin/bash -c \
        "kubectl port-forward $POD ${PORT}:${PORT}"
    sleep 1
}

new_namespace() {
    : ${NAMESPACE:?new_namespace requires NAMESPACE to be set, --new-namespace namespace}
    
    kubectl create namespace ${NAMESPACE}
    kubectl --namespace=${NAMESPACE} create serviceaccount vault
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------

while true; do
  case "$1" in
    -c | --context ) 
        CONTEXT=$2; 
        use_context;
        shift 2;;
    -v | --vault-addr ) VAULT_ADDR=$2; shift 2;;
    -vca | --vault-cacert ) VAULT_CACERT=$2; shift 2;;

    -p | --port-forward ) port_forward $2 $3; shift 3;;
    -s | --setup ) setup; shift;;
    --token-reviewer-jwt ) get_token_reviewer_jwt; shift; break;;
    -h | --k8s-host ) get_k8s_host; shift; break;;
    --k8s-cacert ) get_k8s_cacert; shift; break;;    
    -n | --new-namespace ) 
        NAMESPACE=$2;
        new_namespace;
        shift 2;;

    -- ) shift; break ;;
    * ) break ;;
  esac
done