


path "database/+/creds/dbuser" {
  capabilities = ["read"]
  mfa_methods  = ["db_otp"]
}