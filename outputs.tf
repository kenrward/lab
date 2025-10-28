output "dc_ip" {
  value = split("/", var.dc_static_ip)[0]
}

output "ready_check_url" {
  description = "Readiness probe URL for the Domain Controller"
  value       = module.ad_forest_dc.ready_check_url
}

output "vm_id" {
  description = "VM ID of the Domain Controller in Proxmox"
  value       = module.ad_forest_dc.vm_id
}