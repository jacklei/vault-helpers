# vault-helpers

## Testing
Create a temporary pod to test the connectivity to vault.
```
kubectl -n demo run -it --rm --image=alpine --serviceaccount=vault test -- /bin/sh
apk add --update vim curl bash jq
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
 curl --header "X-Vault-Token: $TOKEN" -s -k  https://vault.stage.opcon.dev:8200/v1/database/creds/demo-app | jq .
```