module "ad_forest_dc" {
  source         = "./modules/ad_forest_dc"
  vm_name        = local.vms["dc"].name
  domain_fqdn    = var.domain_fqdn
  netbios_name   = var.netbios_name
  admin_password = var.admin_password
  dsrm_password  = var.dsrm_password
  ready_port     = var.ready_port
  ready_path     = var.ready_path
  node           = var.node

  ci_user     = "Administrator"
  ci_password = var.initial_admin_password

  template_vm_id = var.base_template_id
  target_storage = var.storage

}
