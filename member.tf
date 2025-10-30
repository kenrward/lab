module "win_member" {
  for_each = {
    for name, cfg in local.vms : name => cfg if cfg.role == "member"
  }

  source = "./modules/win_member"



  # --- Basic domain info ---
  vm_name        = each.key
  domain_fqdn    = var.domain_fqdn
  netbios_name   = var.netbios_name
  admin_password = var.admin_password
  dc_ip          = module.ad_forest_dc.dc_ip


  # --- vSphere environment ---
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_network    = var.vsphere_network
  vsphere_datastore  = var.vsphere_datastore
  vsphere_host       = "192.168.1.51"
  template_name      = var.template_name
  folder             = var.folder
  gateway            = var.gateway

  # --- Hardware ---
  cores        = var.cores
  memory_mb    = var.memory_mb
  disk_size_gb = var.disk_size_gb

  # --- Domain join credentials ---
  join_username = "Administrator"
  join_password = var.admin_password
  ci_password   = var.admin_password

  # --- Ready check ---
  ready_check_url = module.ad_forest_dc.ready_check_url

  depends_on = [null_resource.wait_for_dc]
}
