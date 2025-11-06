
########################################
# Create Windows Member Server VM
########################################

resource "vsphere_virtual_machine" "seg" {
  name             = var.vm_name
  resource_pool_id = local.resource_pool_id 
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.folder

  num_cpus  = var.cores
  memory    = var.memory_mb
  guest_id  = "windows2019srv_64Guest"
  scsi_type = "lsilogic-sas"
  firmware         = "efi"

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "${var.vm_name}.vmdk"
    size             = var.disk_size_gb
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
  template_uuid = data.vsphere_virtual_machine.template.id

  customize {
    windows_options {
      computer_name  = var.vm_name
      admin_password = var.admin_password
      time_zone      = 035  
    }

    network_interface {}
  }
}


  ########################################
  # Cloudbase-Init (Userdata Injection)
  ########################################

  extra_config = {
      "guestinfo.metadata"           = base64encode(templatefile("${path.module}/metadata.yaml", {
      hostname = var.vm_name
    }))
     "guestinfo.userdata"           = base64encode(templatefile("${path.module}/userdata-seg.tpl", {
      HOSTNAME       = var.vm_name
      DOMAIN_FQDN    = var.domain_fqdn
      NETBIOS_NAME   = var.netbios_name
      READY_URL      = var.ready_check_url
      READY_PORT     = var.ready_check_port
      READY_PATH     = var.ready_check_path
      ADMIN_PASSWORD = var.admin_password
      JOIN_USERNAME  = var.join_username
      JOIN_PASSWORD  = var.join_password
      DC_IP          = var.dc_ip
      SEGTOKEN        = var.segtoken
    }))
    "guestinfo.userdata.encoding" = "base64"
  }
  # Enable VMware Tools interaction (needed for guestinfo)
  tools_upgrade_policy = "manual"
  wait_for_guest_net_timeout = 10
  
  # Allow Terraform to destroy and recreate when template changes
  lifecycle {
    ignore_changes = [
      clone[0].template_uuid
    ]
  }
}

