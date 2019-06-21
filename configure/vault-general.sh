#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

policy=
# entity_name=
# mount_accessor=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
policy() {    
    accessor=$(configure/vault-auth-kubernetes.sh --accessor)

    vault policy write ${policy} -<<EOF
path "database/creds/{{identity.entity.aliases.${accessor}.metadata.service_account_namespace}}-db" {
  capabilities = ["read"]
}
EOF
}

# write_entity() {
#   # : ${token_reviewer_jwt:?configure requires token_reviewer_jwt to be set, --token-reviewer-jwt jwt}
#   # : ${kubernetes_host:?configure requires kubernetes_host to be set, --k8s-host host}

#   # entity
#   vault write identity/entity \
#     name="demo-app" \
#     policies="demo-db-r"
  
#   # entity id
#   entity_id=$(vault read identity/entity/name/demo-app -format=json | jq -r .data.id)

#   # alias
#   vault write identity/entity-alias name="vault" \
#         canonical_id=${entity_id} \
#         mount_accessor=$(configure/vault-auth-kubernetes.sh --accessor) 
# }

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------

while true; do
  case "$1" in

    -p | --policy )
        policy=$2; 
        policy; 
        shift 2;;
    # -e | --entity ) write_entity; shift;;


    -- ) shift; break ;;
    * ) break ;;
  esac
done