

# --- Domain FQDN ---
output "domain_fqdn" {
  value = var.domain_fqdn
}

# --- Domain Controller IP ---
output "dc_ip" {
  description = "Primary IPv4 address of the Domain Controller"
  value       = local.dc_ip
}

# --- HTTP readiness probe URL ---
output "ready_check_url" {
  description = "HTTP readiness probe URL for the DC"
  value       = "http://${local.dc_ip}:${var.ready_port}${local.ready_check_path != "" ? local.ready_check_path : "/"}"
}

output "vm_id" {
  description = "VM ID of the Domain Controller in vSphere"
  value       = vsphere_virtual_machine.dc.id
}
