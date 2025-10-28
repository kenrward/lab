
module "win_member" {
  for_each = {
    for name, cfg in local.vms : name => cfg if cfg.role == "member"
  }
  source         = "./modules/win_member"
  vm_name        = each.key
  domain_fqdn    = var.domain_fqdn
  netbios_name   = var.netbios_name
  admin_password = var.admin_password
  node           = var.node
  dc_ip          = module.ad_forest_dc.dc_ip

  # --- Required module inputs ---
  template_vm_id = var.base_template_id
  target_storage = var.storage
  join_username  = "Administrator"
  join_password  = var.admin_password
  ci_password    = var.admin_password

  # --- Optional health/ready check ---
  ready_check_url = "http://${module.ad_forest_dc.dc_ip}:8080"

  depends_on = [module.ad_forest_dc]
}
