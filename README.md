# 🧪 Lab Infrastructure Automation

This repository contains Terraform configurations and automation scripts to deploy a full Windows lab environment on **Proxmox VE**.  
It automates domain controller and member server provisioning using **Cloudbase-Init** and Windows Server 2022 templates.

---

## 📁 Repository Structure

| Path | Description |
|------|--------------|
| `cloudbase/` | Cloudbase-Init templates, configs, and YAML user-data for Windows images |
| `modules/` | Reusable Terraform modules (network, VM, AD, etc.) |
| `dc.tf` | Domain Controller deployment definition |
| `member.tf` | Member Server deployment definition |
| `locals.tf` | Common locals for naming, roles, and configuration maps |
| `providers.tf` | Terraform provider configuration (Proxmox, variables) |
| `variables.tf` | Input variables and defaults |
| `outputs.tf` | Terraform output definitions |
| `tf.sh` | Helper shell script for Terraform workflow (`init`, `plan`, `apply`, `destroy`) |

---

## ⚙️ Requirements

- **Proxmox VE 8.x+** with a storage pool named `local-zfs`  
- **Terraform v1.6+**  
- **Windows Server 2022 ISO** uploaded to Proxmox  
- **Cloudbase-Init** installed in the image  

---

## 🚀 Usage

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview plan
terraform plan

# Apply configuration
terraform apply
