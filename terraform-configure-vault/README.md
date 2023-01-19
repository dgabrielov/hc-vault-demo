HashiCorp Vault Demo - Configuration via Terraform Cloud/Enterprise
------------

We can now use Terraform to configure Vault! 

 
```WARNING:``` may expose secrets in Terraform state file - use this as an example only and keep secrets safe!

Prerequisites
------------

1. Vault Enterprise instance address + accessible port + token with permissions (root token works too)
1. Paste these values into `variables.auto.tfvars`
1. Modify `backend.tf` with your TFC/E organization and workspace


Usage
------------

Start run via UI/VCS-driven workflow in TFC/TFE