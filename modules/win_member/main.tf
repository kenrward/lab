########################################
# modules/win_member/main.tf
# Deploy Windows Member Server on vSphere
########################################

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
  guest_id  = "windows2019srvNext_64Guest"
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
        admin_password = var.ci_password
      }

      network_interface {
        ipv4_address = null
        ipv4_netmask = null
      }

      # Set gateway at the top-level of the customize block
      ipv4_gateway = var.gateway
    }
  }

  ########################################
  # Cloudbase-Init (Userdata Injection)
  ########################################

  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/userdata-member.tpl", {
      HOSTNAME       = var.vm_name
      DOMAIN_FQDN    = var.domain_fqdn
      NETBIOS_NAME   = var.netbios_name
      READY_URL      = var.ready_check_url
      ADMIN_PASSWORD = var.admin_password
      JOIN_USERNAME  = var.join_username
      JOIN_PASSWORD  = var.join_password
      DC_IP          = var.dc_ip
    }))
    "guestinfo.userdata.encoding" = "base64"
  }

  # Allow Terraform to destroy and recreate when template changes
  lifecycle {
    ignore_changes = [
      clone[0].template_uuid
    ]
  }
}

