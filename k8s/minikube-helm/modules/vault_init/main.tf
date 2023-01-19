locals {
  project_name = var.project_name
  replicas = var.k8s_replicas
  outputs_path = var.outputs_path
  vault_auto_init = var.vault_auto_init
}

resource "time_sleep" "wait_60s" {
  count = local.vault_auto_init ? 1 : 0

  depends_on = [
    var.module_helm
  ]
  create_duration = "60s"
}

resource "null_resource" "vault_init" {
  count = local.vault_auto_init ? 1 : 0

  depends_on = [
    time_sleep.wait_60s
  ]


  provisioner "local-exec" {
    command = "minikube kubectl -p=${local.project_name} -- exec -t ${local.project_name}-0 -- vault operator init -key-shares=1 -key-threshold=1 > ${local.outputs_path}/vault-init-output.txt && cat ${local.outputs_path}/vault-init-output.txt | sed -n -e 's/^.*Root Token: //p' > ${local.outputs_path}/root_token.txt && cat ${local.outputs_path}/vault-init-output.txt | grep '^Unseal' | rev | cut -d ' ' -f 1 | rev > ${local.outputs_path}/unseal_key.txt"
  }
}

resource "time_sleep" "wait_15s" {
  count = local.vault_auto_init ? 1 : 0

  depends_on = [
    null_resource.vault_init
  ]
  create_duration = "15s"
}


data "local_sensitive_file" "vault_unsealkey" {
  count = local.vault_auto_init ? 1 : 0

  depends_on = [
    time_sleep.wait_15s
  ]

  filename = "${var.outputs_path}/unseal_key.txt"
}

resource "null_resource" "vault_unseal" {
  count = local.vault_auto_init ? 1 : 0

  depends_on = [
    time_sleep.wait_15s
  ]

  provisioner "local-exec" {
    command = "sleep 15 && minikube kubectl -p=${local.project_name} -- exec -t ${local.project_name}-0 -- vault operator unseal ${element(data.local_sensitive_file.vault_unsealkey[*].content, count.index)}"
  }
}

resource "null_resource" "vault_join_cluster" {
  count = local.vault_auto_init ? local.replicas : 0
  depends_on = [
    null_resource.vault_unseal
  ]

  provisioner "local-exec" {
    command = "sleep 15 && minikube kubectl -p=${local.project_name} -- exec -t ${local.project_name}-${count.index} -- vault operator raft join http://${local.project_name}-0.${local.project_name}-internal:8200"
  }
}

resource "null_resource" "vault_unseal_standbys" {
  count = local.vault_auto_init ? local.replicas : 0

  depends_on = [
    null_resource.vault_join_cluster
  ]

  provisioner "local-exec" {
    command = "sleep 15 && minikube kubectl -p=${local.project_name} -- exec -t ${local.project_name}-${count.index} -- vault operator unseal ${element(data.local_sensitive_file.vault_unsealkey[*].content, count.index)}"
  }
}