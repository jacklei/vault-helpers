#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

context=
vault_addr=
namespace=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------

use_context() {
    kubectl config use-context ${context:-minikube} &> /dev/null
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

    }

get_token_reviewer_jwt() {
    # get the name of the secret corresponding to the service account
    secret_name="$(kubectl get serviceaccount vault-auth \
        -o go-template='{{ (index .secrets 0).name }}')"

    # get the actual token reviewer account
    tr_account_token="$(kubectl get secret ${secret_name} \
        -o go-template='{{ .data.token }}' | base64 --decode)"

    echo "${tr_account_token}"
}

get_k8s_host() {
    # found from https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#without-kubectl-proxy
    k8s_host="$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")"

    echo "${k8s_host}"
}

get_k8s_cacert() {
    # found from https://github.com/kubernetes/kubernetes/issues/61572
    k8s_cacert="$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')"

    echo "${k8s_cacert}"
}

port_forward() {
    app="$1"
    port="$2"
    pod="$(kubectl get pod -l app="$app" -o jsonpath='{.items[0].metadata.name}')"
    screen -dms "$pod" /bin/bash -c \
        "kubectl port-forward $pod ${port}:${port}"
    sleep 1
}

new_namespace() {
    : ${namespace:?new_namespace requires namespace to be set, --new-namespace namespace}
    
    kubectl create namespace ${namespace}
    kubectl --namespace=${namespace} create serviceaccount vault

    # create a config map to store the vault address
    : ${vault_addr:?setup requires vault_addr to be set, --vault-addr https://vault_addr}
    kubectl --namespace=${namespace} create configmap vault \
        --from-literal "vault_addr=${vault_addr}"

    : ${vault_cacert:?setup requires vault_cacert to be set, --vault-cacert /tmp/ca.pem}
    # create a secret for our ca
    kubectl --namespace=${namespace} create secret generic vault-tls \
        --from-file "${vault_cacert}"

}

helm() {
    kubectl create clusterrolebinding tiller-cluster-admin \
        --clusterrole=cluster-admin --serviceaccount=kube-system:default
    helm init --upgrade --wait
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------

while true; do
  case "$1" in
    -c | --context ) 
        context=$2; 
        use_context;
        shift 2;;
    -v | --vault-addr ) vault_addr=$2; shift 2;;
    -vca | --vault-cacert ) vault_cacert=$2; shift 2;;
    --helm ) helm; shift;;
    -p | --port-forward ) port_forward $2 $3; shift 3;;
    -s | --setup ) setup; shift;;
    --token-reviewer-jwt ) get_token_reviewer_jwt; shift; break;;
    -h | --k8s-host ) get_k8s_host; shift; break;;
    --k8s-cacert ) get_k8s_cacert; shift; break;;    
    -n | --new-namespace ) 
        namespace=$2;
        new_namespace;
        shift 2;;

    -- ) shift; break ;;
    * ) break ;;
  esac
done