#cloud-config
hostname: ${HOSTNAME}

write_files:
  - path: C:\Windows\Temp\join_domain.ps1
    permissions: '0644'
    content: |
      $domainFqdn = "${DOMAIN_FQDN}"
      $adminPlain = "${ADMIN_PASSWORD}"
      $dcIp       = "${DC_IP}"

      # Set DNS to point to DC
      $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
      Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dcIp

      # Wait for domain DNS to resolve
      $max = 30
      for ($i = 0; $i -lt $max; $i++) {
          if (Test-Connection -ComputerName $domainFqdn -Count 1 -Quiet) { break }
          Start-Sleep -Seconds 5
      }

      # Join domain
      Add-Computer -DomainName $domainFqdn -Credential (New-Object PSCredential("Administrator", (ConvertTo-SecureString $adminPlain -AsPlainText -Force))) -Restart
runcmd:
  - [ powershell.exe, -NoLogo, -NoProfile, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\join_domain.ps1" ]
