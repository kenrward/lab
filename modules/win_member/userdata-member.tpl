#cloud-config
hostname: ${HOSTNAME}

write_files:
  - path: C:\Windows\Temp\join_domain.ps1
    content: |
      $maxTries = 12
      $try = 0
      while ($try -lt $maxTries) {
          $iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name -First 1
          if ($iface) {
              Write-Host "Found network interface: $iface"
              try {
                  Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses ${DC_IP}
                  Write-Host "DNS server set to ${DC_IP}"
                  break
              } catch {
                  Write-Host "Failed to set DNS: $_"
              }
          } else {
              Write-Host "Network interface not ready, waiting..."
          }
          Start-Sleep -Seconds 10
          $try++
      }

      $readyUrl = "${READY_URL}"
      $readyPort = ${READY_PORT}
      $readyPath = "${READY_PATH}"
      if (-not [string]::IsNullOrWhiteSpace($readyPath) -and -not $readyPath.StartsWith("/")) {
          $readyPath = "/$readyPath"
      }
      $dcIp = "${DC_IP}"
      if ([string]::IsNullOrWhiteSpace($readyUrl) -and -not [string]::IsNullOrWhiteSpace($dcIp)) {
          $readyUrl = "http://$dcIp:$readyPort$readyPath"
      }
      if ($readyUrl -and $readyUrl.Trim().Length -gt 0) {
          Write-Host "Waiting for domain controller readiness signal at $readyUrl"
          $maxReadyChecks = 60
          for ($i = 0; $i -lt $maxReadyChecks; $i++) {
              try {
                  $response = Invoke-WebRequest -Uri $readyUrl -UseBasicParsing -TimeoutSec 10
                  if ($response.Content -match 'READY') {
                      Write-Host "Received READY response from domain controller."
                      break
                  }
                  Write-Host "Readiness probe returned unexpected content."
              } catch {
                  Write-Host "Domain controller not ready yet: $_"
              }
              Start-Sleep -Seconds 30
          }
      } else {
          Write-Host "No readiness URL provided; proceeding without probe."
      }

      # Optionally join the domain after DNS succeeds
      try {
          $domain = "${DOMAIN_FQDN}"
          $user = "${JOIN_USERNAME}"
          $pass = ConvertTo-SecureString "${JOIN_PASSWORD}" -AsPlainText -Force
          $cred = New-Object System.Management.Automation.PSCredential ($user, $pass)
          Add-Computer -DomainName $domain -Credential $cred -Force -ErrorAction Stop
          Write-Host "Successfully joined domain."
      } catch {
          Write-Host "Domain join failed: $_"
      }

      # Reboot safely
      Write-Host "Rebooting in 10 seconds..."
      Start-Sleep -Seconds 10
      Restart-Computer -Force
runcmd:
  - powershell.exe -ExecutionPolicy Bypass -File C:\Windows\Temp\join_domain.ps1
