########################################
# Outputs
########################################

output "vm_id" {
  description = "vSphere VM ID for this member server"
  value       = vsphere_virtual_machine.member.id
}

output "vm_name" {
  description = "Name of the member server VM"
  value       = vsphere_virtual_machine.member.name
}

output "ipv4_addresses" {
  description = "List of IPv4 addresses assigned to the member VM"
  value       = flatten(vsphere_virtual_machine.member.guest_ip_addresses)
}

