variable "namespaces" {
  type = object({
    it      = bool
    it_mfa  = bool
    finance = bool
    hr      = bool
  })

  default = {
    finance = true
    hr      = true
    it      = true
    it_mfa  = false
  }
}

variable "default_password" {
  default = "changeme"
}