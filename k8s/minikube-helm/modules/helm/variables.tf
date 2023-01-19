variable "project_name" {
  type = string
}

variable "k8s_replicas" {
  description = "Number of stable replica Pods running at any given time."
  default = 5
  type = number
}

variable "outputs_path" {
  
}