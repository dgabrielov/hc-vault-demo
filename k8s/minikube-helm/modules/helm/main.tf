
locals {
  project_name = var.project_name
  replicas = var.k8s_replicas
  outputs_path = var.outputs_path
}

resource "helm_release" "vault" {
  name       = local.project_name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  timeout    = 600

  /*
  set {
    name = ""
    value = ""
  }
*/
  set {
    name  = "global.tlsDisable"
    value = "true"
  }

  # UI Settings
  set {
    name  = "ui.enabled"
    value = "true"
  }
  set {
    name  = "ui.serviceType"
    value = "LoadBalancer"
  }
  set {
    name  = "ui.serviceNodePort"
    value = "null"
  }
  set {
    name  = "ui.externalPort"
    value = "18200"
  }
  set {
    name  = "ui.activeVaultPodOnly"
    value = "true"
  }

  set {
    name  = "server.enabled"
    value = "true"
  }
  set {
    name  = "server.image.repository"
    value = "hashicorp/vault-enterprise"
  }
  set {
    name  = "server.image.tag"
    value = "1.12.2-ent"
  }
  set {
    name  = "server.enterpriseLicense.secretName"
    value = "vault-ent-license"
  }
  set {
    name  = "server.enterpriseLicense.secretKey"
    value = "license.hclic"
  }
  set {
    name  = "server.readinessProbe.enabled"
    value = "false"
  }
  set {
    name  = "server.livenessProbe.enabled"
    value = "false"
  }

  set {
    name  = "server.dataStorage.enabled"
    value = "true"
  }
  set {
    name  = "server.auditStorage.enabled"
    value = "true"
  }
  set {
    name  = "server.standalone.enabled"
    value = "false"
  }
  set {
    name  = "server.affinity"
    value = ""
  }

  # HA Settings

  set {
    name  = "server.ha.enabled"
    value = "true"
  }
  set {
    name  = "server.ha.replicas"
    value = local.replicas
  }
  set {
    name  = "server.ha.raft.enabled"
    value = "true"
  }
  set {
    name  = "server.ha.raft.setNodeId"
    value = "true"
  }
  set {
    name  = "server.ha.raft.config"
    value = <<EOT
ui = true
api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"
listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}

storage "raft" {
  path = "/vault/data"
}

service_registration "kubernetes" {}
EOT
  }
}


