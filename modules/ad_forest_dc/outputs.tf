output "domain_fqdn" { value = var.domain_fqdn }
output "dc_ip" {
  value = local.dc_ip
}

output "ready_check_url" {
  value = "http://${local.dc_ip}:${var.ready_port}${var.ready_path}"
}
