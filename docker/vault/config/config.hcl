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
cluster_addr = "http://127.0.0.1:8201"
ui = true