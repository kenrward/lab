module "zn_seg_server" {
  source              = "./modules/zn_seg_server"
  vm_name             = "seg01"
  vsphere_datacenter  = var.vsphere_datacenter
  vsphere_datastore   = var.vsphere_datastore
  vsphere_network     = var.vsphere_network
  vsphere_host        = "192.168.1.51"
  template_name       = var.template_name
  domain_fqdn         = "lab.local"
  join_username       = "LAB\\Administrator"
  join_password       = var.admin_password
  admin_password      = var.admin_password
  gateway             = "192.168.11.1"
  dc_ip               = module.ad_forest_dc.dc_ip
  install_script      = "C:\\Installers\\SegSetup.exe /quiet /norestart"
  ready_check_url     = module.ad_forest_dc.ready_check_url
  ready_check_port    = var.ready_port
  ready_check_path    = module.ad_forest_dc.ready_check_path

  depends_on = [null_resource.wait_for_dc]
}
