module "ad_forest_dc" {
  source = "./modules/ad_forest_dc"

  # --- Basic AD/DC Configuration ---
  vm_name        = local.vms["dc"].name
  domain_fqdn    = var.domain_fqdn
  netbios_name   = var.netbios_name
  admin_password = var.admin_password
  dsrm_password  = var.dsrm_password
  dc_static_ip   = var.dc_static_ip
  gateway        = var.gateway

  # --- vSphere Environment ---
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_network    = var.vsphere_network
  vsphere_datastore  = var.vsphere_datastore
  template_name      = var.template_name
  vsphere_host       = "192.168.1.51"
  folder             = var.folder

  # --- VM Hardware ---
  cores        = var.cores
  memory_mb    = var.memory_mb
  disk_size_gb = var.disk_size_gb

  # --- Readiness Signal ---
  ready_port = var.ready_port
  ready_path = var.ready_path

}

# --- Wait until the DC has a valid IP and responds on readiness port ---
resource "null_resource" "wait_for_dc" {
  depends_on = [module.ad_forest_dc]

  provisioner "local-exec" {
    command = <<-EOT
      echo "⏳ Waiting for DC IP for $VM_NAME..."
      echo "DEBUG: GOVC_URL=$GOVC_URL"

      # Poll vSphere for a valid IP
      for i in {1..60}; do
        ip=$(govc vm.info -json "$VM_NAME" | jq -r 'try .virtualMachines[]?.guest?.ipAddress // .virtualMachines[]?.summary?.guest?.ipAddress // empty')
        if [ -n "$ip" ] && [ "$ip" != "0.0.0.0" ] && [[ ! "$ip" =~ ^169\\.254\\. ]]; then
          echo "✅ Found DC IP: $ip"
          break
        fi
        echo "⏱️ IP not ready (currently: $ip), retrying ($i/60)..."
        sleep 10
      done

      if [ -z "$ip" ] || [ "$ip" = "0.0.0.0" ] || [[ "$ip" =~ ^169\\.254\\. ]]; then
        echo "❌ Timed out waiting for DC IP."
        exit 1
      fi

      echo "🌐 Detected DC IP: $ip — probing readiness at $READY_URL"
      for i in {1..90}; do
        # Use -s for silent, -f for fail silently on server errors, -m for timeout
        RESPONSE=$(curl -sfm 5 "$READY_URL") 
        if echo "$RESPONSE" | grep -q READY; then
          echo "✅ DC is READY (responded on $ip)"
          exit 0
        fi
        
        # New: Print the response when it fails to match "READY"
        echo "DEBUG: Readiness check response was: '$RESPONSE'"
        
        echo "⏱️ Retry ($i/90)..."
        sleep 30
      done
      echo "❌ Timed out waiting for Domain Controller readiness."
      exit 1
    EOT

    environment = {
      GOVC_URL      = var.vsphere_server
      GOVC_USERNAME = var.vsphere_user
      GOVC_PASSWORD = var.vsphere_password
      GOVC_INSECURE = "true"
      VM_NAME       = module.ad_forest_dc.vm_name
      READY_PORT    = var.ready_port
      READY_PATH    = module.ad_forest_dc.ready_check_path
      READY_URL     = module.ad_forest_dc.ready_check_url
    }
  }
}
