#!/usr/bin/dumb-init /bin/bash

export VAULT_NAMESPACE=it

CICD_AUTH_TOKEN=$(vault token create -field=token -policy=cicd-auth-only -ttl=10m -period=10m)
#echo $CICD_AUTH_TOKEN

#rm -f ~/.vault-token
rm -f /tmp/app-token

export VAULT_TOKEN=${CICD_AUTH_TOKEN}

ROLE_ID=$(vault read -field=role_id auth/approle/role/cicd/role-id)
#echo "ROLE ID=${ROLE_ID}"
WRAPPED_TOKEN=$(vault write -wrap-ttl=60s -force -field=wrapping_token auth/approle/role/cicd/secret-id)
#echo "WRAPPED_TOKEN=${WRAPPED_TOKEN}"
SECRET_ID=$(VAULT_TOKEN="${WRAPPED_TOKEN}" vault unwrap -field=secret_id)
#echo "SECRET ID=${SECRET_ID}"
vault write -field=token auth/approle/login role_id="${ROLE_ID}" \
    secret_id="${SECRET_ID}" > /tmp/app-token
#echo "APP TOKEN=${APP_TOKEN}"