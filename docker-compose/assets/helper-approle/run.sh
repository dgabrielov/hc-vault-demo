#!/usr/bin/dumb-init /bin/bash

export VAULT_NAMESPACE=it

function vaultstatuscheck(){
        vault status | grep Sealed | awk '{print $2}'
}

while [[ `vaultstatuscheck` = "true" ]]; do
  sleep 1s
done

sleep 2

case `vaultstatuscheck` in
    "false")
        #clear
        echo -e "\nVault is unsealed!\n"
        ;;
    "true")
        #clear
        echo -e "\nERROR: There was an error unsealing Vault, exiting...\n"
        exit 1;
        ;;
    *)
        #clear
        echo -e "\nThere was an error unsealing Vault - is the service running? \nMore info:"
        exit 1;
        ;;
esac

sleep 15

# Using this method instead of $VAULT_TOKEN as per
# this issue: https://github.com/hashicorp/vault/issues/6501
vault login token=$(jq -r '.auth.client_token' /tmp/outputs/superadmin-login.txt)

# Enable approle on vault
vault auth enable approle
vault policy write cicd-auth-only $POLICIESDIR/cicd-auth-only.hcl
vault policy write cicd-read-secrets $POLICIESDIR/cicd-read-secrets.hcl

# This method lets us control the maximum
# number of times the token can be used
vault write auth/approle/role/cicd \
    secret_id_num_uses=5 \
    secret_id_ttl=5m \
    token_num_uses=5 \
    token_ttl=5m \
    token_policies="cicd-read-secrets" \
    token_max_ttl=5m 
    token_bound_cidrs="${NWCIDRBLOCK}"
    secret_id_bound_cidrs="${NWCIDRBLOCK}" \
    
#vault read -field=role_id auth/approle/role/cicd/role-id > /tmp/role-id
#vault write -force -field=secret_id auth/approle/role/cicd/secret-id > /tmp/secret-id

tail -f dev/null