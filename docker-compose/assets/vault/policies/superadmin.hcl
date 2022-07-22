

path "*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/*" {
  capabilities = [ "create", "read", "update", "delete", "sudo" ]
}

# To configure the SSH secrets engine
path "ssh/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# To create the test user
path "auth/userpass/users/*" {
  capabilities = [ "create", "update" ]
}
