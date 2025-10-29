# --- Domain FQDN ---
output "domain_fqdn" {
  value = var.domain_fqdn
}

# --- Domain Controller IP ---
output "dc_ip" {
  description = "Primary IPv4 address of the Domain Controller (from static configuration)"
  # Strip /24 from "192.168.86.210/24"
  value = split("/", var.dc_static_ip)[0]
}

# --- HTTP readiness probe URL ---
output "ready_check_url" {
  description = "HTTP readiness probe URL for the DC"
  value       = "http://${split("/", var.dc_static_ip)[0]}:${var.ready_port}/"
}

output "vm_id" {
  description = "VM ID of the Domain Controller in vSphere"
  value       = vsphere_virtual_machine.dc.id
}
