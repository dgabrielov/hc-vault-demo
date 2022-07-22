

path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
  mfa_methods = ["db_otp"]
}
