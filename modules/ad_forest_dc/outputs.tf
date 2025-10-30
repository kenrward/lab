

# --- Domain FQDN ---
output "domain_fqdn" {
  value = var.domain_fqdn
}

# --- Dynamically detect the DC's IP via VMware Tools ---
output "dc_ip" {
  description = "DC IP after VMware Tools reports it"
  value       = try(data.vsphere_virtual_machine.dc_refreshed.default_ip_address, null)
}

output "ready_check_url" {
  value = "Computed dynamically during wait"
}


# --- Optional for debugging ---
output "vm_id" {
  description = "vSphere VM ID of the DC"
  value       = vsphere_virtual_machine.dc.id
}
