variable "vm_name" {
  type = string
  default = "lab-ad-dc01"
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

variable "ci_user" {
  type    = string
  default = "Administrator"
}

variable "ci_password" {
  type = string
}


variable "template_vm_id" {
  type = number
}

variable "domain_fqdn" {
  type = string
}

variable "netbios_name" {
  type = string
}

variable "dsrm_password" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "ready_port" {
  type    = number
  default = 8080
}

variable "ready_path" {
  type    = string
  default = "/ready"
}

variable "disk_size_gb" {
  type    = number
  default = 100
}
