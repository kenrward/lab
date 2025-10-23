module "win_member" {
  source         = "./modules/win_member"
  vm_name        = local.vms["win2022-app1"].name
  vm_role        = local.vms["win2022-app1"].role
  domain_fqdn    = var.domain_fqdn
  admin_password = var.admin_password
  node           = var.node

  depends_on     = [module.ad_forest_dc]
  dc_ip          = module.ad_forest_dc.dc_ip
}
