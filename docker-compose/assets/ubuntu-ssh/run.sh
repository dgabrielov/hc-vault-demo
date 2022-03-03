#!/usr/bin/dumb-init /bin/bash

# Generate config for vault-ssh-helper
mkdir -p /etc/vault-ssh-helper.d/
cat << EOF > /etc/vault-ssh-helper.d/config.hcl
vault_addr = "${VAULT_ADDR}"
ssh_mount_point = "ssh"
namespace = "$ROOT_NAMESPACE/it"
tls_skip_verify = true
allowed_roles = "*"
allowed_cidr_list="${NWCIDRBLOCK}"
EOF

# Set PAMD
sed -i -e 's/^@include common-auth/#@include common-auth/g' ${PAMD_CONFIG_PATH} 
echo "auth requisite pam_exec.so quiet expose_authtok log=/var/log/vault-ssh.log /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-ssh-helper.d/config.hcl" | tee -a ${PAMD_CONFIG_PATH}
echo "auth optional pam_unix.so not_set_pass use_first_pass nodelay" | tee -a ${PAMD_CONFIG_PATH}


sed -i -e 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' ${SSHD_CONFIG_PATH} # enable ChallengeResponseAuthentication
sed -i -e 's/UsePAM no/UsePAM yes/g' ${SSHD_CONFIG_PATH} # enable PAM usage
sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/g' ${SSHD_CONFIG_PATH} # disable cleartext tunneling of passwords

sudo service ssh stop
sudo service ssh start

# The helper needs to be started in dev mode because
# TLS was disabled in Vault's config
vault-ssh-helper -dev -config /etc/vault-ssh-helper.d/config.hcl

