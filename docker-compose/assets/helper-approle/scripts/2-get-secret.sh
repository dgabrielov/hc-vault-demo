#!/usr/bin/dumb-init /bin/bash

export VAULT_NAMESPACE=it

APP_TOKEN=$(cat /tmp/app-token)

#VAULT_TOKEN=${APP_TOKEN} vault kv get infosec/checkmarx
VAULT_TOKEN=${APP_TOKEN} vault kv get -format=json -field=data infosec/checkmarx