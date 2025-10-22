module "ad_forest_dc" {
  source         = "./modules/ad_forest_dc"
  vm_name        = "win2022-dc"
  node           = var.node
  pool           = var.pool
  target_storage = var.storage
  bridge         = var.bridge
  cores          = 4
  memory_mb      = 8192
  template_vm_id = var.base_template_id

  ci_user     = "Administrator"
  ci_password = var.initial_admin_password
  #ipconfig0   = "ip=192.168.86.201/24,gw=192.168.86.1"

  domain_fqdn    = "lab.local"
  netbios_name   = "LAB"
  dsrm_password  = var.dsrm_password
  admin_password = var.domain_admin_password

  ready_port = 8080
  ready_path = "/ready"
}
