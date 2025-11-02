
variable "dsrm_password" {
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

# --- Static networking for DC ---
variable "dc_static_ip" {
  description = "Static IPv4 address and prefix for the domain controller (CIDR format)"
  type        = string
  default    = "0.0.0.0/24"
}

variable "gateway" {
  description = "Default IPv4 gateway for static DC networking"
  type        = string
  default     = "192.168.86.1"
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vCenter server FQDN or IP"
  type        = string
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "vsphere_cluster" {
  description = "vSphere cluster name"
  type        = string
}

variable "vsphere_network" {
  description = "vSphere network name"
  type        = string
}

variable "vsphere_datastore" {
  description = "vSphere datastore name"
  type        = string
}

# --- vSphere template + folder ---
variable "template_name" {
  description = "Name of the Windows Server template to clone from"
  type        = string
}

variable "folder" {
  description = "Optional folder in vSphere to place the VM"
  type        = string
  default     = ""
}

# --- VM hardware defaults ---
variable "cores" {
  description = "Number of vCPUs for the DC"
  type        = number
  default     = 4
}

variable "memory_mb" {
  description = "RAM size (MB) for the DC"
  type        = number
  default     = 8192
}

variable "disk_size_gb" {
  description = "Primary disk size (GB) for the DC"
  type        = number
  default     = 150
}

