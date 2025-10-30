variable "vm_name" {}
variable "vsphere_datacenter" {}
variable "vsphere_datastore" {}
variable "vsphere_network" {}
variable "resource_pool_id" {}
variable "template_name" {}
variable "domain_fqdn" {}
variable "join_username" {}
variable "join_password" {}
variable "admin_password" {}
variable "install_script" {
  description = "Optional path or command to install the SegServer app"
  default     = "C:\\Installers\\SegSetup.exe /quiet /norestart"
}
variable "gateway" {}
variable "disk_size_gb" { default = 80 }
variable "cores" { default = 2 }
variable "memory_mb" { default = 4096 }

variable "vsphere_host" {
  description = "ESXi host name for resource pool lookup"
}
