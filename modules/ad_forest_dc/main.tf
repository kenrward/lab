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
  name          = var.vsphere_host
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
  }

  # --- Cloudbase-Init metadata and user-data ---
  extra_config = {
    "guestinfo.metadata"           = base64encode(templatefile("${path.module}/metadata.yaml", {
      hostname = var.vm_name
    }))
    "guestinfo.metadata.encoding"  = "base64"

    "guestinfo.userdata"           = base64encode(templatefile("${path.module}/userdata-dc.tpl", {
      HOSTNAME       = var.vm_name
      DOMAIN_FQDN    = var.domain_fqdn
      NETBIOS_NAME   = var.netbios_name
      DSRM_PASSWORD  = var.dsrm_password
      ADMIN_PASSWORD = var.admin_password
      READY_PORT     = var.ready_port
      READY_PATH     = var.ready_path
      hostname       = var.vm_name         # 👈 add this line
    }))
    "guestinfo.userdata.encoding"  = "base64"
  }


  # Enable VMware Tools interaction (needed for guestinfo)
  tools_upgrade_policy = "manual"
  wait_for_guest_net_timeout = 0
}
