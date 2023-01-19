terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    local = {
      source = "hashicorp/local"
    }
    helm = {
      source = "hashicorp/helm"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "null" {
  # Configuration options
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = local.project_name
  }
}