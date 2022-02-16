#!/usr/bin/dumb-init /bin/bash

helpdeskhosts=(
    "windows-hosts"
    "macos-hosts"
)

infosecapps=(
    "nessus"
    "splunk"
    "carbonblack"
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
  "people-ops"
)

vault operator init > /tmp/vault-init-output.txt

VAULT_TOKEN=$(cat /tmp/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p')

IFS=$'\r\n' GLOBIGNORE='*' command eval \
  "UNSEAL_KEYS=($(cat /tmp/vault-init-output.txt | grep '^Unseal' | rev | cut -d ' ' -f 1 | rev))"

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
vault login token=$(cat /tmp/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p') >/dev/null

echo "" > /vault/logs/vault_audit.log
vault audit enable file file_path=/vault/logs/vault_audit.log
vault namespace create $ROOT_NAMESPACE
vault auth enable -namespace=$ROOT_NAMESPACE userpass

# Superadmin can log into all namespaces incl $ROOT_NAMESPACE
vault policy write -ns=$ROOT_NAMESPACE superadmin $POLICIESDIR/superadmin.hcl
vault write -ns=$ROOT_NAMESPACE auth/userpass/users/superadmin password=$password policies=superadmin

rm -f ~/.vault-token

sleep 5

# Generate superadmin token and continue script 
# with this token
vault login -ns=$ROOT_NAMESPACE -method=userpass username=superadmin password=$password -format=json 2>/dev/null > tmp/superadmin-login.txt

for namespace in ${namespaces[@]}; do
  vault namespace create -namespace=$ROOT_NAMESPACE $namespace
  vault auth enable -namespace=$ROOT_NAMESPACE/$namespace userpass
  vault policy write -ns=$ROOT_NAMESPACE/$namespace superadmin $POLICIESDIR/superadmin.hcl
  vault write -ns=$ROOT_NAMESPACE/$namespace auth/userpass/users/superadmin password=$password policies=superadmin
done

for role in ${itroles[@]}; do
    vault policy write -namespace=$ROOT_NAMESPACE/it $role $POLICIESDIR/$role.hcl
    vault write -namespace=$ROOT_NAMESPACE/it auth/userpass/users/$role password=$password policies=$role
    vault login -no-store -ns=$ROOT_NAMESPACE/it -method=userpass username=$role password=$password > tmp/$role-login.txt
done

vault policy write -ns=$ROOT_NAMESPACE/it rotate-windows $POLICIESDIR/rotate-windows.hcl
vault token create -ns=$ROOT_NAMESPACE/it -period 72h -policy rotate-windows > tmp/win-main-token.txt


# hruser - readonly within people-ops namespace
vault policy write -ns=$ROOT_NAMESPACE/people-ops hruser $POLICIESDIR/hruser.hcl
vault write -ns=$ROOT_NAMESPACE/people-ops auth/userpass/users/hruser password=$password policies=hruser


# finuser - readonly within finance namespace
vault policy write -ns=$ROOT_NAMESPACE/finance finuser $POLICIESDIR/finuser.hcl
vault write -ns=$ROOT_NAMESPACE/finance auth/userpass/users/finuser password=$password policies=finuser



# GENERATE & PUT SECRETS

# FINANCE SECTION
vault secrets enable -namespace=$ROOT_NAMESPACE/finance -path="accounting" -version=1 kv
vault kv put -namespace=$ROOT_NAMESPACE/finance accounting/QuickBooksOnline "FinanceUser"=`passgen`

vault secrets enable -namespace=$ROOT_NAMESPACE/people-ops -path="recruiting" -version=1 kv
vault kv put -namespace=$ROOT_NAMESPACE/people-ops recruiting/LinkedInRecruiter "RecruitingUser"=`passgen`
vault kv put -namespace=$ROOT_NAMESPACE/people-ops recruiting/Salesforce "RecruitingUser"=`passgen`
vault secrets enable -namespace=$ROOT_NAMESPACE/people-ops -path="human-resources" -version=1 kv
vault kv put -namespace=$ROOT_NAMESPACE/people-ops human-resources/Workday "HRUser"=`passgen`
vault kv put -namespace=$ROOT_NAMESPACE/people-ops human-resources/ADP "HRUser"=`passgen`


# HELPDESK SECTION
vault secrets enable -namespace=$ROOT_NAMESPACE/it -path="helpdesk" -version=2 kv
for host in ${helpdeskhosts[@]}; do
    vault kv put -namespace=$ROOT_NAMESPACE/it helpdesk/secrets/$host "HelpdeskUser"=`passgen`
done

# INFOSEC SECTION
vault secrets enable -namespace=$ROOT_NAMESPACE/it -path="infosec" -version=2 kv
for app in ${infosecapps[@]}; do
    vault kv put -namespace=$ROOT_NAMESPACE/it infosec/$app "InfoSecUser"=`passgen`
done

# INFRA SECTION

vault secrets enable -namespace=$ROOT_NAMESPACE/it -path="infra" -version=2 kv

vault kv put -namespace=$ROOT_NAMESPACE/it "infra/${infra[0]}" "InfraUser"=`passgen`
vault kv put -namespace=$ROOT_NAMESPACE/it "infra/${infra[1]}" "InfraUser"=`passgen`
vault kv put -namespace=$ROOT_NAMESPACE/it "infra/${infra[2]}" "DOOR ACCESS CODE"="565023"

vault secrets enable -namespace=$ROOT_NAMESPACE/it -path="database/$dataset" database


# Setup secrets-gen
# We must log in as the root user again to do this
rm -f ~/.vault-token

vault login token=$(cat /tmp/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p') >/dev/null

SHA256=$(sha256sum "/vault/config/plugins/vault-secrets-gen" | cut -d ' ' -f1)

vault plugin register -sha256="${SHA256}" -command="vault-secrets-gen" secret secrets-gen

vault secrets enable -ns=$ROOT_NAMESPACE/it -path="passgen" -plugin-name="secrets-gen" plugin

rm -f ~/.vault-token

vault login token=$(jq -r '.auth.client_token' tmp/superadmin-login.txt)

# create SSH Secret Engine
vault secrets enable -ns=$ROOT_NAMESPACE/it ssh
vault policy write -ns=$ROOT_NAMESPACE/it ssh-otp $POLICIESDIR/ssh-otp.hcl
vault write -ns=$ROOT_NAMESPACE/it auth/userpass/users/ubuntu password=$password policies=ssh-otp

# create role for engine
vault write -ns=$ROOT_NAMESPACE/it ssh/roles/otp_key_role \
key_type=otp \
default_user=ubuntu \
cidr_list=$NWCIDRBLOCK

export UBUNTU_IP=$(getent hosts ubuntu | awk '{print $1}')

vault write -ns=$ROOT_NAMESPACE/it ssh/creds/otp_key_role ip=$UBUNTU_IP

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
vault write -namespace=$ROOT_NAMESPACE/it database/$dataset/config/$POSTGRES_DB plugin_name=postgresql-database-plugin allowed_roles="*" connection_url="postgres://{{username}}:{{password}}@postgres:5432/$POSTGRES_DB?sslmode=disable" username=$POSTGRES_USER password=$POSTGRES_PASSWORD

# Create Vault role "dbuser" that creates credentials
vault write -namespace=$ROOT_NAMESPACE/it database/$dataset/roles/dbuser db_name=$POSTGRES_DB creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT; GRANT dbuser TO \"{{name}}\";" default_ttl="30m" max_ttl="24h"

# Create Vault role "dbuser" that creates credentials
vault write -namespace=$ROOT_NAMESPACE/it database/$dataset/roles/dbadmin db_name=$POSTGRES_DB creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT; GRANT dbadmin TO \"{{name}}\";" default_ttl="30m" max_ttl="24h"

# Rotate root credentials
#vault write -force database/$datasetrotate-root/$POSTGRES_DB



# SSH OTP

vault login -no-store -ns=$ROOT_NAMESPACE/it -method=userpass username=ubuntu password=$password -format=json > tmp/ubuntu-login.txt

export UBUNTU_IP=$(getent hosts ubuntu | awk '{print $1}')

#vault write -ns=$ROOT_NAMESPACE/it ssh/creds/otp_key_role ip=$UBUNTU_IP

echo "Enter this command: vault ssh -ns=$ROOT_NAMESPACE/it -role otp_key_role -mode otp -strict-host-key-checking=no ubuntu@$UBUNTU_IP"

tail -f dev/null