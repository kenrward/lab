#!/usr/bin/env bash
set -e

echo "Applying Terraform..."
terraform apply -auto-approve

echo "Refreshing state to capture Proxmox VM IPs..."
terraform refresh -no-color

echo "Running wrapper function..."
terraform apply -target=null_resource.wait_for_dc -auto-approve

echo "Outputs:"
terraform output
