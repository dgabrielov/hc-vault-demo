



path "infra/+/windows-servers/*" {
  capabilities = ["create", "update"]
}


# Allow hosts to generate new passwords
path "passgen/password" {
  capabilities = ["update"]
}