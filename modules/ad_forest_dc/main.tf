terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.57.0"
    }
  }
}

locals {
  dc_ip = flatten(proxmox_virtual_environment_vm.dc.ipv4_addresses)[0]
}


# 1) Upload Cloud-Init user-data snippet as a Proxmox "snippets" file
resource "proxmox_virtual_environment_file" "dc_userdata" {
  content_type = "snippets"
  datastore_id = "local" # adjust if you store snippets elsewhere
  node_name    = var.node
  source_raw {
    data = templatefile("${path.module}/userdata-dc.tpl", {
      DOMAIN_FQDN    = var.domain_fqdn
      NETBIOS_NAME   = var.netbios_name
      DSRM_PASSWORD  = var.dsrm_password
      ADMIN_PASSWORD = var.admin_password # Retaining this, though it's unused in the PS script
      READY_PORT     = var.ready_port
      READY_PATH     = var.ready_path
    })
    file_name = "userdata-${var.vm_name}.yaml"
  }
}

# 2) Create the DC VM by cloning your generalized Win 2022 + Cloudbase-Init template
resource "proxmox_virtual_environment_vm" "dc" {
  name        = var.vm_name
  node_name   = var.node
  pool_id     = var.pool
  description = "AD Forest DC for ${var.domain_fqdn}"

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    interface    = "scsi0"
    size         = var.disk_size_gb
    datastore_id = var.target_storage
    discard      = "on"
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  agent {
    enabled = true
  }

  boot_order = ["scsi0"]

  # Cloud-Init: user, pass, and custom user-data snippet
  initialization {
    datastore_id = var.target_storage
    user_account {
      username = var.ci_user
      password = var.ci_password
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.dc_userdata.id

  }
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.dc.vm_id
}
