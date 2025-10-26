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

# Active Directory domain FQDN (e.g. lab.local)
variable "domain_fqdn" {
  description = "Fully qualified domain name for the new AD forest"
  type        = string
}

# NetBIOS name (e.g. LAB)
variable "netbios_name" {
  description = "NetBIOS name of the Active Directory domain"
  type        = string
}

# Administrator password (used for both local admin and domain join)
variable "admin_password" {
  description = "Administrator password for Windows VMs"
  type        = string
  sensitive   = true
}

# Ready probe TCP port (used by DC post-promotion signal)
variable "ready_port" {
  description = "Port to open when DC is fully promoted (readiness probe)"
  type        = number
  default     = 8080
}

# Ready probe filesystem path (used by DC post-promotion signal)
variable "ready_path" {
  description = "Path to create when DC is ready (used as readiness flag)"
  type        = string
  default     = "/Ready"
}

variable "vms" {
  description = "Map of virtual machines and their roles/names"
  type = map(object({
    name = string
    role = string
  }))
}

