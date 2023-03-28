terraform {
  cloud {
    organization = "dgtest1"

    workspaces {
      name = "hc-vault-demo"
    }
  }
}
