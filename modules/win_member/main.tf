# --- vSphere Environment Data Sources ---
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "esxi" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id

  join_domain_ps1 = templatefile("${path.module}/join_domain.ps1.tpl", {
    DC_IP_JSON          = jsonencode(var.dc_ip)
    READY_URL_JSON      = jsonencode(var.ready_check_url)
    READY_PORT          = var.ready_check_port
    READY_PATH_JSON     = jsonencode(var.ready_check_path)
    DOMAIN_FQDN_JSON    = jsonencode(var.domain_fqdn)
    JOIN_USERNAME_JSON  = jsonencode(var.join_username)
    JOIN_PASSWORD_JSON  = jsonencode(var.join_password)
  })

  join_domain_ps1_b64 = base64encode(replace(local.join_domain_ps1, "\n", "\r\n"))
}

########################################
# Create Windows Member Server VM
########################################

resource "vsphere_virtual_machine" "member" {
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
  }

  ########################################
  # Cloudbase-Init (Userdata Injection)
  ########################################

  extra_config = {
    "guestinfo.metadata" = base64encode(templatefile("${path.module}/metadata.yaml", {
      hostname = var.vm_name
    }))
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/userdata-member.tpl", {
      HOSTNAME              = var.vm_name
      JOIN_DOMAIN_PS1_B64   = local.join_domain_ps1_b64
    }))
    "guestinfo.metadata.encoding" = "base64"
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

