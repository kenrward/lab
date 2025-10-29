# --- Data sources ---
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

data "vsphere_host" "esxi" {
  name          = "192.168.1.51"
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  resource_pool_id = data.vsphere_host.esxi.resource_pool_id
  dc_ip = vsphere_virtual_machine.dc.default_ip_address != "" ? vsphere_virtual_machine.dc.default_ip_address : split("/", var.dc_static_ip)[0]

  ready_check_path = var.ready_path != "" ? (
    startswith(var.ready_path, "/") ? var.ready_path : "/${var.ready_path}"
  ) : ""
}


data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# --- Domain Controller VM ---
resource "vsphere_virtual_machine" "dc" {
  name             = var.vm_name
  resource_pool_id = local.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.folder
  num_cpus         = var.cores
  memory           = var.memory_mb
  guest_id         = "windows2019srvNext_64Guest"
  scsi_type        = "lsilogic-sas"
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
        time_zone      = 35 # Eastern US
      }

      # DHCP configuration
      network_interface {}

      # No ipv4_gateway here — DHCP provides it automatically
    }
}

}

