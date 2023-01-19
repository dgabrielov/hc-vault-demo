variable "vault_host" {
  description = "ip or hostname of the vault server"
  default     = ""
}

variable "vault_port_ext" {
  description = "the configured port to connect to the vault server"
  default     = "8200"
}

variable "vault_token" {
  default = ""
}

variable "default_password" {
  default = "changeme"
}