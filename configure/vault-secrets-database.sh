#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

SECRETS_ENGINE_PATH=
DATABASE_NAME=
DATABASE_HOST=
DATABASE_USERNAME=
DATABASE_PASSWORD=
ROLE_NAME=
ROLE_CREATION_STATEMENTS=
ROLE_DEFAULT_TTL=
ROLE_MAX_TTL=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function enable() {
    vault secrets enable ${SECRETS_ENGINE_PATH:+"-path=$SECRETS_ENGINE_PATH"} database
}

function configure() {
    : ${ROLE_NAME:?configure requires ROLE_NAME to be set, --role-name role_name}
    : ${DATABASE_NAME:?configure requires DATABASE_NAME to be set, --db-name database_name}

    vault write ${SECRETS_ENGINE_PATH:-database}/config/${DATABASE_NAME} \
        plugin_name=mysql-database-plugin \
        connection_url="{{username}}:{{password}}@tcp(${DATABASE_HOST:-127.0.0.1})/" \
        allowed_roles="${ROLE_NAME}" \
        username="${DATABASE_USERNAME:-root}" \
        password="${DATABASE_PASSWORD:-password}"
}

function role() {
    : ${ROLE_NAME:?role requires ROLE_NAME to be set, --role-name role_name}
    : ${DATABASE_NAME:?role requires DATABASE_NAME to be set, --db-name database_name}

    vault write ${SECRETS_ENGINE_PATH:-database}/roles/${ROLE_NAME} \
        db_name=${DATABASE_NAME} \
        creation_statements="${SECRETS_ENGINE_PATH:-CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';}" \
        default_ttl="1h" \
        max_ttl="24h"
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
while true; do
  case "$1" in
    -d | --db-name ) DATABASE_NAME=$2; shift 2;;
    -h | --host ) DATABASE_HOST=$2; shift 2;;
    -u | --username ) DATABASE_USERNAME=$2; shift 2;;
    -p | --password ) DATABASE_PASSWORD=$2; shift 2;;
    -rn | --role-name ) ROLE_NAME=$2; shift 2;;
    --creation-statements ) ROLE_CREATION_STATEMENTS=$2; shift 2;;
    --default-ttl ) ROLE_DEFAULT_TTL=$2; shift 2;;
    --max-ttl ) ROLE_MAX_TTL=$2; shift 2;;

    -e | --enable ) enable; shift;;
    -c | --configure ) configure; shift;;
    -r | --role ) role; shift;;
    * ) break ;;
  esac
done