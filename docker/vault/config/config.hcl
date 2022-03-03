storage "file" {
  path    = "vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

disable_mlock = true

license_path = "vault/config/vault.hclic"

plugin_directory = "vault/config/plugins"

api_addr = "http://0.0.0.0:8200"
ui = true

cluster_name = "vault-demo"
telemetry {
  dogstatsd_addr = "telegraf:8125"
  enable_hostname_label = true
  prometheus_retention_time = "0h"
}