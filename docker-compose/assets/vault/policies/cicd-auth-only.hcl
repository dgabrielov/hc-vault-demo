
# Grant 'read' permission on the 'auth/approle/role/cicd/role-id' path
path "auth/approle/role/cicd/role-id" {
   capabilities = [ "read" ]
}

# Grant 'update' permission on the 'auth/approle/role/cicd/secret-id' path
path "auth/approle/role/cicd/secret-id" {
   capabilities = [ "update" ]
}
