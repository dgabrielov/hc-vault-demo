variable "it_data" {
  type = object({
    helpdesk = list(string)
    infra    = list(string)
    infosec  = list(string)
    dbadmin  = optional(list(string))
    dbuser   = optional(list(string))
  })
  default = {
    helpdesk = ["windows-hosts", "macos-hosts"]
    infra    = ["cisco", "hp", "datacenter", "windows-servers", "nix-servers"]
    infosec  = ["nessus", "splunk", "carbonblack", "checkmarx"]
  }
  description = "IT Team names as well as labels for KV store keys."
}

variable "default_password" {
}

variable "use_cases" {
  type = object({
    ssh_otp = bool
    kv_v2   = bool
    db = object({
      postgres = bool
    })
  })

  default = {
    db = {
      postgres = true
    }
    kv_v2   = true
    ssh_otp = true
  }
}