#!/usr/bin/env bash
set -e

echo "🚀 Applying Terraform..."
terraform apply -auto-approve

echo "🔄 Refreshing state to capture Proxmox VM IPs..."
terraform refresh -no-color

echo "📡 Outputs:"
terraform output
