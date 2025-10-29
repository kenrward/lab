
module "ad_forest_dc" {
  source = "./modules/ad_forest_dc"

  # --- Basic AD/DC Configuration ---
  vm_name        = local.vms["dc"].name
  domain_fqdn    = var.domain_fqdn
  netbios_name   = var.netbios_name
  admin_password = var.admin_password
  dsrm_password  = var.dsrm_password
  ci_password    = var.admin_password
  dc_static_ip   = var.dc_static_ip
  gateway        = var.gateway

  # --- vSphere Environment ---
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_network    = var.vsphere_network
  vsphere_datastore  = var.vsphere_datastore
  template_name      = var.template_name
  folder             = var.folder

  # --- VM Hardware ---
  cores        = var.cores
  memory_mb    = var.memory_mb
  disk_size_gb = var.disk_size_gb

  # --- Misc legacy compatibility ---
  node           = "vsphere" # placeholder (required by module interface)
  target_storage = var.vsphere_datastore
  template_vm_id = 0 # unused in vSphere mode, safe placeholder

  # --- Readiness Signal ---
  ready_port = var.ready_port
  ready_path = var.ready_path
}

#######################################
# Wait for DC to signal readiness
#######################################

resource "null_resource" "wait_for_dc" {
  depends_on = [module.ad_forest_dc]

  provisioner "local-exec" {
    command     = <<EOT
      echo "⏳ Waiting for Domain Controller (${module.ad_forest_dc.dc_ip}) to signal readiness..."
      sleep 15
      for i in {1..90}; do
        if curl -sf ${module.ad_forest_dc.ready_check_url} | grep -q READY; then
          echo "✅ Domain Controller is READY (responded on ${module.ad_forest_dc.ready_check_url})"
          exit 0
        fi
        echo "⏱️  DC not ready yet... retrying ($i/90)"
        sleep 30
      done
      echo "❌ Timed out waiting for Domain Controller readiness after 45 minutes"
      exit 1
    EOT
    interpreter = ["bash", "-c"]
  }

  triggers = {
    dc_ip           = module.ad_forest_dc.dc_ip
    ready_check_url = module.ad_forest_dc.ready_check_url
  }
}
