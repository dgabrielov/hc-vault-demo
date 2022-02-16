

# to list SSH secrets path
path "ssh/*" {
  capabilities = ["list"]
}

# to use the configured SSH secrets engine otp_key_role otp_key_role
path "ssh/creds/otp_key_role" {
  capabilities = ["create", "read", "update"]
}