

module "root" {
  source = "./modules/root"

}


module "it" {
  source = "./modules/it"

  depends_on = [
    module.root
  ]

  providers = {
    vault = vault.it
  }

  default_password = var.default_password
}


module "finance" {
  source = "./modules/finance"

  depends_on = [
    module.root
  ]
  providers = {
    vault = vault.finance
  }

  default_password = var.default_password
}

module "hr" {
  depends_on = [
    module.root
  ]

  source = "./modules/hr"
  providers = {
    vault = vault.hr
  }

  default_password = var.default_password
}