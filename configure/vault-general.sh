#!/usr/bin/env bash
set -x
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

POLICY_NAME=
POLICY_PATH=
CAPABILITIES=()

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
policy() {
    : ${POLICY_NAME:?policy requires POLICY_NAME to be set, --policy-name name}
    : ${CAPABILITIES:?policy requires CAPABILITIES to be set, --capabilities cap1}

    CAPABILITIES_JOINED=$(printf ",\"%s\"" "${CAPABILITIES[@]}")
    vault policy write ${POLICY_NAME} -<<EOF
path "${POLICY_PATH:-database/creds/readonly}" {
  capabilities = [${CAPABILITIES_JOINED:1}]
}
EOF
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------

while true; do
  case "$1" in
    -c | --capabilities ) CAPABILITIES+=("$2"); shift 2;;
    -pn | --policy-name ) POLICY_NAME=$2; shift 2;;
    -pp | --policy-path ) POLICY_PATH=$2; shift 2;;

    -p | --policy ) policy; shift;;


    -- ) shift; break ;;
    * ) break ;;
  esac
done