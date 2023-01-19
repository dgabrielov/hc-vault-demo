terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "vault" {
  address = "http://${var.vault_host}:${var.vault_port_ext}"
  token   = var.vault_token
}

provider "vault" {
  alias     = "finance"
  namespace = "finance"
  address   = "http://${var.vault_host}:${var.vault_port_ext}"
  token     = var.vault_token
}

provider "vault" {
  alias     = "it"
  namespace = "it"
  address   = "http://${var.vault_host}:${var.vault_port_ext}"
  token     = var.vault_token
}

provider "vault" {
  alias     = "hr"
  namespace = "hr"
  address   = "http://${var.vault_host}:${var.vault_port_ext}"
  token     = var.vault_token
}