output "dc_ip" {
  description = "Primary IPv4 address of the Domain Controller"
  value       = module.ad_forest_dc.dc_ip
}

output "ready_check_url" {
  description = "Readiness probe URL for the Domain Controller"
  value       = module.ad_forest_dc.ready_check_url
}
