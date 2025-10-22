variable "node" {
  type = string
}

variable "node_name" {
  type        = string
  default     = "pve"
  description = "Target Proxmox node"
}

variable "pool" {
  type    = string
  default = null
}

variable "storage" {
  type    = string
  default = "local-zfs"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "base_template_id" {
  type    = number
  default = 8002
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "initial_admin_password" {
  type      = string
  sensitive = true
}

variable "dsrm_password" {
  type      = string
  sensitive = true
}

variable "domain_admin_password" {
  type      = string
  sensitive = true
}

variable "joiner_password" {
  type      = string
  sensitive = true
}

