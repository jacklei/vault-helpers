# Vault Helpers

### Project status: in development
The configuration of vault with kubernetes have been completed. The project still needs to include the initial bootstrap of Vault.

## Overview
A collection of scripts to configure Hashicorp Vault. 

## Configuration Scripts
* [vault-general](configure/vault-general.sh)
  * Adds policies
* [vault-auth-kubernetes](configure/vault-auth-kubernetes.sh)
  * Enables Kubernetes authentication method
  * Configures new Kubernetes clusters
  * Adds new roles for new namespaces/service accounts
* [vault-secrets-database](configure/vault-secrets-database.sh)
  * Enables the database secrets engine
  * Configures new database connection
  * Adds new roles for dynamic secrets
  * Rotates root password
* [kubernetes](configure/kubernetes.sh)
  * Use context (assumes context exists)
  * Setup resources for vault
    * Adds token reviewer service account
    * Grants service account the token reviewer permission
    * Adds a configmap with Vault's address
    * Adds Vault's `ca.pem` file into a secret
  * Get the token reviewers JWT 
  * Get the kubernetes api host
  * Get the kubernetes ca certificate in base64
  * Port forward a pod to localhost
  * Create a namespace with a vault service account


## Getting Started
### Prerequisites
* `$VAULT_TOKEN` with root permissions
* `$VAULT_CACERT` is a self-signed cert that exists on disk

## Assumptions
Scripts are generic, but the Makefile has assumptions. These will be configurable later.

* `common-stage` and `kubes-stage-la` contexts exists in kube conf
* Vault exists on the `common-stage` context
* Vault is ran on port `8200`
* Apps cluster will be on the `kubes-stage-la` context
* Apps cluster can access Vault via `https://vault.stage.opcon.dev:8200`
* Apps cluster can access database via `demo2db.stage.opcon.dev:3306`
  * username: `root`
  * password: `cloudnext`
* Vault has been `initialized` and `unsealed`

## Usage
1. Setup kubernetes, port-forward vault, enable database secrets engine and kubernetes auth method.
   ```
   make all
   ```
2. Add a new namespace and database. Then plumb everything up.
   ```
   make newapp
   ```

## Testing
Create a temporary pod to test the connectivity to vault.
```
kubectl -n demo run -it --rm --image=alpine --serviceaccount=vault test -- /bin/sh
apk add --update vim curl bash jq mysql-client
bash
```

Grab the service account token.
```
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

Curl out to vault with the proper JWT to get your temp token to retrieve secrets. Save that.
```
curl --request POST --data '{"jwt": "$JWT", "role": "demo"}' -s -k https://vault.stage.opcon.dev:8200/v1/auth/kubernetes/login | jq '.auth.client_token'
```

Get your dynamic secret using the temporary token.
```
curl --header "X-Vault-Token: $TOKEN" -s -k  https://vault.stage.opcon.dev:8200/v1/database/creds/demo-role | jq .
```

Try it out.
```
mysql -u$USER -p$PASS -h demo2db.stage.opcon.dev
```

