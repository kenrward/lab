

# --- Domain FQDN ---
output "domain_fqdn" {
  value = var.domain_fqdn
}

# --- Domain Controller IP ---
output "dc_ip" {
  description = "DC IP (not available until VMware Tools reports it)"
  value       = coalesce(local.dc_ip, "DHCP / unknown at apply time")
}

output "ready_check_url" {
  description = "HTTP readiness probe URL for the DC"
  value       = local.dc_ip != null ? "http://${local.dc_ip}:${var.ready_port}${var.ready_path != "" ? var.ready_path : "/"}" : "Unavailable (DC uses DHCP)"
}

output "vm_id" {
  description = "VM ID of the Domain Controller in vSphere"
  value       = vsphere_virtual_machine.dc.id
}
