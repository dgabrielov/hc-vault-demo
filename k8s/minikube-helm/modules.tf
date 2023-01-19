
locals {
  outputs_path = "${path.module}/tmp/outputs"
  vault_auto_init = true # auto-initializes Vault (WARNING: may expose secrets in Terraform state file - use at your own risk!)
  k8s_replicas = 5
  project_name = "vault-mk"
}





module "helm" {
    source = "./modules/helm"
  project_name = local.project_name
  k8s_replicas = local.k8s_replicas
  outputs_path = local.outputs_path
}

module "vault_init" {
    source = "./modules/vault_init"
  vault_auto_init = local.vault_auto_init
    project_name = local.project_name
  k8s_replicas = local.k8s_replicas
  outputs_path = local.outputs_path

  module_helm = module.helm
}
