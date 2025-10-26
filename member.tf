resource "null_resource" "wait_for_dc" {
  depends_on = [module.ad_forest_dc]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for DC to signal readiness..."
      for i in {1..90}; do
        if curl -sf ${module.ad_forest_dc.ready_check_url} | grep -q READY; then
          echo "✅ DC is ready!"
          exit 0
        fi
        echo "⏳ DC not ready yet... retrying ($i/90)"
        sleep 10
      done
      echo "❌ Timed out waiting for DC readiness"
      exit 1
    EOT
    interpreter = ["bash", "-c"]
  }
}




module "win_member" {
  source         = "./modules/win_member"
  vm_name        = local.vms["app1"].name
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

  depends_on = [null_resource.wait_for_dc]
}
