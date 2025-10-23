module "ad_forest_dc" {
  source         = "./modules/ad_forest_dc"
  vm_name        = local.vms["win2022-dc"].name
  vm_role        = local.vms["win2022-dc"].role
  domain_fqdn    = var.domain_fqdn
  netbios_name   = var.netbios_name
  admin_password = var.admin_password
  dsrm_password  = var.dsrm_password
  ready_port     = var.ready_port
  ready_path     = var.ready_path
  node           = var.node

  ci_user     = "Administrator"
  ci_password = var.initial_admin_password


  domain_fqdn    = "lab.local"
  netbios_name   = "LAB"
  dsrm_password  = var.dsrm_password
  admin_password = var.domain_admin_password

  ready_port = 8080
  ready_path = "/ready"
}
