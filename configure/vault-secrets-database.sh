#!/usr/bin/env bash
###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------

secrets_engine_path=
database_name=
database_host=
database_username=
database_password=
role_name=
role_creation_statements=
role_default_ttl=
role_max_ttl=

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
enable() {
    vault secrets enable ${secrets_engine_path:+"-path=$secrets_engine_path"} database
}

configure() {
    : ${role_name:?configure requires role_name to be set, --role-name role_name}
    : ${database_name:?configure requires database_name to be set, --db-name database_name}

    vault write ${secrets_engine_path:-database}/config/${database_name} \
        plugin_name=mysql-database-plugin \
        connection_url="{{username}}:{{password}}@tcp(${database_host:-127.0.0.1})/" \
        allowed_roles="${role_name}" \
        username="${database_username:-root}" \
        password="${database_password:-password}"
}

rotate_root() {
    : ${database_name:?rotate_root requires database_name to be set, --db-name database_name}

    vault write -f ${secrets_engine_path:-database}/rotate-root/${database_name}
}

role() {
    : ${role_name:?role requires role_name to be set, --role-name role_name}
    : ${database_name:?role requires database_name to be set, --db-name database_name}

    vault write ${secrets_engine_path:-database}/roles/${role_name} \
        db_name=${database_name} \
        creation_statements="${secrets_engine_path:-CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';}" \
        default_ttl="${role_default_ttl:-1h}" \
        max_ttl="${role_max_ttl:-24h}"
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
while true; do
  case "$1" in
    --secrets-engine-path ) secrets_engine_path=$2; shift 2;;
    -d | --db-name ) database_name=$2; shift 2;;
    -h | --host ) database_host=$2; shift 2;;
    -u | --username ) database_username=$2; shift 2;;
    -p | --password ) database_password=$2; shift 2;;
    --creation-statements ) role_creation_statements=$2; shift 2;;
    --default-ttl ) role_default_ttl=$2; shift 2;;
    --max-ttl ) role_max_ttl=$2; shift 2;;
    --role-name ) role_name=$2; shift 2;;

    -e | --enable ) enable; shift;;
    -c | --configure ) configure; shift;;
    --rotate-root ) rotate_root; shift;;
    -r | --role ) role; shift;;

    -- ) shift; break ;;
    * ) break ;;
  esac
done