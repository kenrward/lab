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
  description = "vSphere template name for cloning"
  type        = string
}

variable "folder" {
  description = "vSphere VM folder (optional)"
  type        = string
  default     = ""
}


variable "vm_name" {
  type        = string
  default     = "lab-ad-dc01"
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
  default = 150
}

variable "dc_static_ip" {
  description = "Static IPv4 address for the domain controller (include CIDR)"
  type        = string
  default     = "192.168.86.210/24"
}

variable "gateway" {
  description = "Default gateway for static IPs"
  type        = string
  default     = "192.168.86.1"
}

variable "vsphere_host" {
  description = "Name or IP of the ESXi host where the VM will be created"
  type        = string
}
variable "guest_version" {
  description = "vSphere guest OS version identifier"
  type        = string
}
