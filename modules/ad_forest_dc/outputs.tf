output "domain_fqdn" { value = var.domain_fqdn }
output "dc_ip" {
  description = "Primary IPv4 address of the Domain Controller (filtered)"
  value = try(
    tolist([
      for ip in flatten([
        for iface in proxmox_virtual_environment_vm.dc.ipv4_addresses : iface
        if length(iface) > 0
      ]) : ip
      if length(trimspace(ip)) > 0
      && !startswith(ip, "169.254.")
      && !startswith(ip, "127.")
    ])[0],
    "0.0.0.0"
  )
}
output "ready_check_url" {
  description = "HTTP readiness probe URL for the DC"
  value = "http://${try(
    tolist([
      for ip in flatten([
        for iface in proxmox_virtual_environment_vm.dc.ipv4_addresses : iface
        if length(iface) > 0
      ]) : ip
      if length(trimspace(ip)) > 0
      && !startswith(ip, "169.254.")
      && !startswith(ip, "127.")
    ])[0],
    "0.0.0.0"
  )}:${var.ready_port}/"
}

output "vm_id" {
  description = "VM ID of the Domain Controller in Proxmox"
  value       = proxmox_virtual_environment_vm.dc.id
}