terraform {
  cloud {
    organization = "jaware-hc-demos"

    workspaces {
      name = "hc-vault-demo-tfconfig"
    }
  }
}