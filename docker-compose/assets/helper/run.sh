#!/usr/bin/dumb-init /bin/bash

helpdeskhosts=(
    "windows-hosts"
    "macos-hosts"
)

infosecapps=(
    "nessus"
    "splunk"
    "carbonblack"
    "checkmarx"
)

infra=(
  "cisco"
  "hp"
  "datacenter"
  "windows-servers"
  "nix-servers"
)

function passgen() {
    openssl rand -base64 16
}

itroles=(
    "infosec" 
    "dbadmin"
    "dbuser"
    "infra"
    "helpdesk"
)


namespaces=(
  "finance"
  "it"
  "it-mfa"
  "hr"
)

echo "" > /tmp/outputs/vault_audit.log
echo "" > /tmp/outputs/vault_metrics.log

vault operator init > /tmp/outputs/vault-init-output.txt

VAULT_TOKEN=$(cat /tmp/outputs/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p')

IFS=$'\r\n' GLOBIGNORE='*' command eval \
  "UNSEAL_KEYS=($(cat /tmp/outputs/vault-init-output.txt | grep '^Unseal' | rev | cut -d ' ' -f 1 | rev))"

function vaultstatuscheck(){
        vault status | grep Sealed | awk '{print $2}'
}

echo -e "\n Unsealing Vault..."

KEY_INDEX=0
while [[ `vaultstatuscheck` = "true" ]]; do
  sleep 1s
  vault operator unseal $(echo "${UNSEAL_KEYS[$KEY_INDEX]}") > /dev/null
  KEY_INDEX=$(( $KEY_INDEX + 1 ))
done

sleep 2

case `vaultstatuscheck` in
    "false")
        #clear
        echo -e "\nVault is now unsealed!\n"
        ;;
    "true")
        #clear
        echo -e "\nERROR: There was an error unsealed Vault, exiting...\n"
        exit 1;
        ;;
    *)
        #clear
        echo -e "\nThere was an error unsealing Vault - is the service running? \nMore info:"
        exit 1;
        ;;
esac

# Using this method instead of $VAULT_TOKEN as per
# this issue: https://github.com/hashicorp/vault/issues/6501
vault login token=$(cat /tmp/outputs/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p') >/dev/null


vault audit enable file file_path=/tmp/outputs/vault_audit.log
vault auth enable userpass

# Superadmin can log into all namespaces incl $ROOT_NAMESPACE
vault policy write superadmin $POLICIESDIR/superadmin.hcl
vault write auth/userpass/users/superadmin password=$password policies=superadmin

vault policy write mfauser $POLICIESDIR/mfauser.hcl
vault write auth/userpass/users/mfauser password=$password policies=mfauser
vault login -no-store -method=userpass username=mfauser password=$password -format=json > /tmp/outputs/mfauser-login.txt

rm -f ~/.vault-token

sleep 5

# Generate superadmin token and continue script 
# with this token
vault login -method=userpass username=superadmin password=$password -format=json 2>/dev/null > /tmp/outputs/superadmin-login.txt

for namespace in ${namespaces[@]}; do
  vault namespace create $namespace
  vault auth enable -ns=$namespace userpass
  vault policy write -ns=$namespace superadmin $POLICIESDIR/superadmin.hcl
  vault write -ns=$namespace auth/userpass/users/superadmin password=$password policies=superadmin
done

export VAULT_NAMESPACE=it

for role in ${itroles[@]}; do
    vault policy write $role $POLICIESDIR/$role.hcl
    vault write auth/userpass/users/$role password=$password policies=$role
    vault login -no-store -method=userpass username=$role password=$password -format=json> /tmp/outputs/$role-login.txt
done

vault policy write rotate-windows $POLICIESDIR/rotate-windows.hcl
vault token create -period 72h -policy rotate-windows > /tmp/outputs/win-main-token.txt

export VAULT_NAMESPACE=hr

# hruser - readonly within hr namespace
vault policy write hruser $POLICIESDIR/hruser.hcl
vault write auth/userpass/users/hruser password=$password policies=hruser
vault login -no-store -method=userpass username=hruser password=$password -format=json > /tmp/outputs/hruser-login.txt

export VAULT_NAMESPACE=finance
# finuser - readonly within finance namespace
vault policy write finuser $POLICIESDIR/finuser.hcl
vault write auth/userpass/users/finuser password=$password policies=finuser



# GENERATE & PUT SECRETS

# FINANCE SECTION
vault secrets enable -path="accounting" -version=1 kv
vault kv put accounting/QuickBooksOnline "FinanceUser"=`passgen`

export VAULT_NAMESPACE=hr
vault secrets enable -path="recruiting" -version=1 kv
vault kv put recruiting/LinkedInRecruiter "RecruitingUser"=`passgen`
vault kv put recruiting/Salesforce "RecruitingUser"=`passgen`
vault secrets enable -path="human-resources" -version=1 kv
vault kv put human-resources/Workday "HRUser"=`passgen`
vault kv put human-resources/ADP "HRUser"=`passgen`

export VAULT_NAMESPACE=it
# HELPDESK SECTION
vault secrets enable -path="helpdesk" -version=2 kv
for host in ${helpdeskhosts[@]}; do
    vault kv put helpdesk/$host Username="Helpdesk" Password=`passgen` 
done

# INFOSEC SECTION
vault secrets enable -path="infosec" -version=2 kv
for app in ${infosecapps[@]}; do
    vault kv put infosec/$app Username="${app}" Password=`passgen` 
done


# INFRA SECTION

vault secrets enable -path="infra" -version=2 kv

vault kv put "infra/${infra[0]}" "InfraUser"=`passgen`
vault kv put "infra/${infra[1]}" "InfraUser"=`passgen`
vault kv put "infra/${infra[2]}" "DOOR ACCESS CODE"="565023"

vault secrets enable -path="database/$dataset" database

unset VAULT_NAMESPACE

# Setup secrets-gen
# We must log in as the root user again to do this
rm -f ~/.vault-token

vault login token=$(cat /tmp/outputs/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p') >/dev/null

SHA256=$(sha256sum "/vault/plugins/vault-secrets-gen" | cut -d ' ' -f1)

vault plugin register -sha256="${SHA256}" -command="vault-secrets-gen" secret secrets-gen

vault secrets enable -path="passgen" -plugin-name="secrets-gen" plugin


rm -f ~/.vault-token

vault login token=$(jq -r '.auth.client_token' /tmp/outputs/superadmin-login.txt)

export VAULT_NAMESPACE=it
# create SSH Secret Engine
vault secrets enable ssh
vault policy write ssh-otp $POLICIESDIR/ssh-otp.hcl
vault write auth/userpass/users/ubuntu password=$password policies=ssh-otp

# create role for engine
vault write ssh/roles/otp_key_role \
key_type=otp \
default_user=ubuntu \
cidr_list=$NWCIDRBLOCK

export UBUNTU_IP=$(getent hosts ubuntu | awk '{print $1}')

vault write ssh/creds/otp_key_role ip=$UBUNTU_IP

# CONFIGURE POSTGRES

psql $POSTGRES_DB -h postgres -U $POSTGRES_USER -c "CREATE SCHEMA $DB_SCHEMA; ALTER DATABASE $POSTGRES_DB SET search_path TO $DB_SCHEMA"

psql -h postgres -d $POSTGRES_DB -f /tmp/seed-db/$dataset-data.sql -U $POSTGRES_USER

# Revoke all permissions on the public schema, so all roles can write to a defined schema
psql $POSTGRES_DB -h postgres -U $POSTGRES_USER -c "REVOKE CONNECT ON DATABASE $POSTGRES_DB FROM PUBLIC; \
REVOKE ALL ON SCHEMA public FROM PUBLIC;"


# Create a Postgres role named "dbuser" and assign privileges
psql $POSTGRES_DB -h postgres -U $POSTGRES_USER -c "CREATE ROLE dbuser NOINHERIT; \
GRANT CONNECT ON DATABASE $POSTGRES_DB TO dbuser; \
GRANT USAGE ON SCHEMA $DB_SCHEMA TO dbuser; \
GRANT SELECT ON ALL TABLES IN SCHEMA $DB_SCHEMA TO dbuser; \
ALTER DEFAULT PRIVILEGES IN SCHEMA $DB_SCHEMA GRANT SELECT ON TABLES TO dbuser;
ALTER ROLE dbuser IN DATABASE $POSTGRES_DB set search_path TO $DB_SCHEMA;"

# Create a Postgres role named "dbadmin" and assign privileges
psql $POSTGRES_DB -h postgres -U $POSTGRES_USER -c "CREATE ROLE dbadmin NOINHERIT; \
GRANT CONNECT ON DATABASE $POSTGRES_DB TO dbadmin; \
GRANT USAGE, CREATE ON SCHEMA $DB_SCHEMA TO dbadmin; \
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $DB_SCHEMA TO dbadmin; \
ALTER DEFAULT PRIVILEGES IN SCHEMA $DB_SCHEMA GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dbadmin; \
GRANT USAGE ON ALL SEQUENCES IN SCHEMA $DB_SCHEMA TO dbadmin; \
ALTER DEFAULT PRIVILEGES IN SCHEMA $DB_SCHEMA GRANT USAGE ON SEQUENCES TO dbadmin;
ALTER ROLE dbadmin IN DATABASE $POSTGRES_DB set search_path TO $DB_SCHEMA;"

# Configure the database secrets engine with the connection credentials for the Postgres database.
# SSL disabled
# not hardcoding credentials in connection_url
vault write database/$dataset/config/$POSTGRES_DB plugin_name=postgresql-database-plugin allowed_roles="*" connection_url="postgres://{{username}}:{{password}}@postgres:5432/$POSTGRES_DB?sslmode=disable" username=$POSTGRES_USER password=$POSTGRES_PASSWORD

# Create Vault role "dbuser" that creates credentials
vault write database/$dataset/roles/dbuser db_name=$POSTGRES_DB creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT; GRANT dbuser TO \"{{name}}\";" default_ttl="30m" max_ttl="24h"

# Create Vault role "dbuser" that creates credentials
vault write database/$dataset/roles/dbadmin db_name=$POSTGRES_DB creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT; GRANT dbadmin TO \"{{name}}\";" default_ttl="30m" max_ttl="24h"

# Rotate root credentials
#vault write -force database/$datasetrotate-root/$POSTGRES_DB



# SSH OTP

vault login -no-store -method=userpass username=ubuntu password=$password -format=json > /tmp/outputs/ubuntu-login.txt

UBUNTU_IP=$(getent hosts ubuntu | awk '{print $1}')

#vault write ssh/creds/otp_key_role ip=$UBUNTU_IP

echo "Enter this command: vault ssh -role otp_key_role -mode otp -strict-host-key-checking=no ubuntu@$UBUNTU_IP"

tail -f dev/null