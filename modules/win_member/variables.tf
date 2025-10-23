variable "vm_name" {
  type = string
}

variable "node" {
  type = string
}

variable "pool" {
  type    = string
  default = null
}

variable "target_storage" {
  type = string
}

variable "cores" {
  type    = number
  default = 4
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "template_vm_id" {
  type = number
}

variable "ci_user" {
  type    = string
  default = "Administrator"
}

variable "ci_password" {
  type = string
}

variable "domain_fqdn" {
  type = string
}

variable "netbios_name" {
  type = string
}

variable "ready_check_url" {
  type = string
}

variable "join_username" {
  type = string
}

variable "join_password" {
  type      = string
  sensitive = true
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "dc_ip" {
  description = "IP address of the domain controller"
  type        = string
}

