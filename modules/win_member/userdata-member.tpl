#cloud-config
hostname: ${HOSTNAME}

write_files:

  - path: C:\Windows\Temp\join_domain.ps1
    permissions: "0644"
    content: |
      [CmdletBinding()]
      param()
      $domainFqdn = "${DOMAIN_FQDN}"
      $dcIp       = "${DC_IP}"
      $adminUser   = "${JOIN_USERNAME}"
      $adminPass   = "${JOIN_PASSWORD}" | ConvertTo-SecureString -AsPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential($adminPass, $adminPass)

      $log = "C:\Windows\Temp\DomainJoin.log"
      Start-Transcript -Path $log -Append
      
      Write-Host "Waiting for network adapter to be ready..."
        $tries = 0
        do {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
            if ($adapters) { break }
            Start-Sleep -Seconds 5
            $tries++
        } until ($adapters -or $tries -ge 20)

        if (-not $adapters) {
            Write-Warning "No active adapters found, skipping DNS config."
        } else {
            Write-Host "Setting DNS to $dcIp on $($adapters.Count) adapter(s)..."
            foreach ($adapter in $adapters) {
                try {
                    Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $dcIp -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to set DNS on $($adapter.InterfaceAlias): $($_.Exception.Message)"
                }
            }
        }


      # --- Wait for DC to respond to LDAP ---
      $maxTries = 60
      for ($i = 1; $i -le $maxTries; $i++) {
          Write-Host "Checking DC LDAP availability... Attempt $i"
          if (Test-NetConnection -ComputerName $dcIp -Port 389 -InformationLevel Quiet) {
              Write-Host "✅ DC LDAP reachable!"
              break
          }
          Start-Sleep -Seconds 10
      }

      # --- Attempt to join domain ---
      for ($i = 1; $i -le 5; $i++) {
          try {
              Add-Computer -DomainName $domainFqdn -Credential $credential -Force -ErrorAction Stop
              Write-Host "✅ Successfully joined domain!"
              Restart-Computer -Force
              break
          } catch {
              Write-Warning "Join failed (attempt $i): $($_.Exception.Message)"
              Start-Sleep -Seconds 15
          }
      }

      Stop-Transcript

runcmd:
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\join_domain.ps1" ]




