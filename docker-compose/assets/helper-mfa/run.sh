#!/usr/bin/dumb-init /bin/bash

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
vault login token=$(cat /tmp/outputs/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p') >/dev/null

# Configure MFA TOTP
# Must be done at the root namespace

vault write sys/mfa/method/totp/mfa \
    issuer=Vault-StepUpMFA \
    period=30 \
    key_size=30 \
    algorithm=SHA256 \
    digits=6

export MFAUSER_BARCODE=$(vault write sys/mfa/method/totp/mfa/admin-generate -format=json \
                        entity_id=$(cat /tmp/outputs/mfauser-login.txt | jq -r '.auth.entity_id') | jq -r '.data.barcode')

echo "step-up MFA: data:image/png;base64,$MFAUSER_BARCODE"


## vault login -method=userpass username=mfauser
## vault kv get -ns=it helpdesk/secrets/macos-hosts (permission denied)
## vault kv get -mfa mfa:959525 -ns=it helpdesk/secrets/macos-hosts (working)

### 

LOGIN_MFA_METHOD_ID=$(vault write -ns=it /identity/mfa/method/totp \
    -format=json \
    generate=true \
    issuer=Vault-LoginMFA \
    period=30 \
    key_size=30 \
    algorithm=SHA256 \
    digits=6 | jq -r '.data.method_id')

export LOGIN_MFA_BARCODE=$(vault write -ns=it /identity/mfa/method/totp/admin-generate -format=json \
                        method_id=$LOGIN_MFA_METHOD_ID entity_id=$(cat /tmp/outputs/helpdesk-login.txt | jq -r '.auth.entity_id') | jq -r '.data.barcode')


echo "login MFA: data:image/png;base64,$LOGIN_MFA_BARCODE"

USERPASS_ACCESSOR=$(vault auth list -ns=it -format=json -detailed | jq -r '."userpass/".accessor')

vault write -ns=it /identity/mfa/login-enforcement/totp \
    mfa_method_ids="$LOGIN_MFA_METHOD_ID" \
    auth_method_accessors=$USERPASS_ACCESSOR


## vault login -ns=it -method=userpass username=helpdesk
    ## vault kv get -ns=it helpdesk/secrets/macos-hosts

tail -f dev/null