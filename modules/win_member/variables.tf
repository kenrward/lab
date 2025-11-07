variable "vm_name" {
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

variable "domain_fqdn" {
  type = string
}

variable "netbios_name" {
  type = string
}

variable "ready_check_url" {
  type = string
}

variable "ready_check_port" {
  type = number
}

variable "ready_check_path" {
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

variable "admin_password" {
  type      = string
  sensitive = true
}

# --- vSphere Environment ---
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

variable "template_name" {
  description = "vSphere template name to clone from"
  type        = string
}

variable "folder" {
  description = "vSphere folder to place VM in (optional)"
  type        = string
  default     = ""
}
variable "gateway" {
  description = "Default IPv4 gateway for the member server"
  type        = string
}

variable "vsphere_host" {
  description = "Name or IP of the ESXi host where the VM will be created"
  type        = string
}

variable "guest_version" {
  description = "vSphere guest OS version identifier"
  type        = string
}

