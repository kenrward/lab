
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
  vsphere_host = "192.168.1.51"
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


# --- Wait until the DC responds on its readiness port ---
resource "null_resource" "wait_for_dc" {
  depends_on = [module.ad_forest_dc]

  provisioner "local-exec" {
    environment = {
      READY_PORT = var.ready_port
      DC_IP      = module.ad_forest_dc.dc_ip != null ? module.ad_forest_dc.dc_ip : ""
    }

    interpreter = ["bash", "-c"]
    command = <<-EOT
      echo "⏳ Waiting for DC's IP from vSphere..."
      ip="$DC_IP"

      # Wait up to 10 minutes for the DC IP if not reported yet
      if [ -z "$ip" ] || [ "$ip" = "null" ]; then
        echo "Waiting for VMware Tools to report IP..."
        for i in {1..60}; do
          ip=$(terraform output -raw dc_ip 2>/dev/null || echo "")
          [ -n "$ip" ] && [ "$ip" != "null" ] && break
          sleep 10
        done
      fi

      if [ -z "$ip" ] || [ "$ip" = "null" ]; then
        echo "❌ Failed to detect DC IP after 10 min"
        exit 1
      fi

      echo "✅ Detected DC IP: $ip"
      echo "Probing readiness at http://$ip:$READY_PORT/"

      for i in {1..90}; do
        if curl -sf "http://$ip:$READY_PORT/" | grep -q READY; then
          echo "✅ DC is READY (responded on $ip)"
          exit 0
        fi
        echo "⏱️ Retry ($i/90)..."
        sleep 30
      done

      echo "❌ Timed out waiting for Domain Controller readiness"
      exit 1
    EOT
  }
}

