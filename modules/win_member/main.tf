terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.57.0"
    }
  }
}

resource "proxmox_virtual_environment_file" "member_userdata" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node
  source_raw {
    data = templatefile("${path.module}/userdata-member.tpl", {
      HOSTNAME      = var.vm_name
      DOMAIN_FQDN   = var.domain_fqdn
      NETBIOS_NAME  = var.netbios_name
      READY_URL     = var.ready_check_url
      ADMIN_PASSWORD = var.admin_password
      JOIN_USERNAME = var.join_username
      JOIN_PASSWORD = var.join_password
      DC_IP = var.dc_ip
    })
    file_name = "userdata-${var.vm_name}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "member" {
  name        = var.vm_name
  node_name   = var.node
  pool_id     = var.pool
  description = "Domain member for ${var.domain_fqdn}"

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }
  memory { dedicated = var.memory_mb }

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

  agent { enabled = true }
  boot_order = ["scsi0"]

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
    user_data_file_id = "${proxmox_virtual_environment_file.member_userdata.datastore_id}:snippets/${proxmox_virtual_environment_file.member_userdata.file_name}"


  }
}
