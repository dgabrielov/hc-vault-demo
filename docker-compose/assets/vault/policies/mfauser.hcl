



path "topsecret/*"
{
  capabilities = [ "read", "list" ]
  mfa_methods = [ "mfa" ]
}

