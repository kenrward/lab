#cloud-config
hostname: ${hostname}

write_files:
  # --- Post-promotion script: runs at startup after AD DS install ---
  - path: C:\Windows\Temp\post_promo.ps1
    permissions: '0644'
    content: |
      [CmdletBinding()]
      param()

      $LogFile = "C:\Windows\Temp\ADDSPostPromo.log"
      Start-Transcript -Path $LogFile -Append

      $readyPort = ${READY_PORT}
      $readyPath = "${READY_PATH}"
      $maxTries  = 120

      Write-Host "Waiting for NTDS service to start..."
      for ($i = 0; $i -lt $maxTries; $i++) {
          try {
              if ((Get-Service NTDS -ErrorAction Stop).Status -eq 'Running') {
                  Write-Host "NTDS is running"
                  break
              }
          } catch {}
          Start-Sleep -Seconds 5
      }

      # Confirm DNS is responding
      try {
          Resolve-DnsName localhost | Out-Null
          Write-Host "DNS is responding"
      } catch {
          Write-Warning "DNS check failed, continuing anyway..."
      }

      # Enable RDP
      Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
      Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' | Out-Null

      # --- Readiness listener ---
      try {
          New-Item -ItemType Directory -Path $readyPath -Force | Out-Null
          netsh advfirewall firewall add rule name="ReadyProbe" dir=in action=allow protocol=TCP localport=$readyPort | Out-Null

          $prefix = "http://+:$readyPort/"
          Write-Host "Starting readiness listener on $prefix"
          $listener = New-Object System.Net.HttpListener
          $listener.Prefixes.Add($prefix)
          $listener.Start()

          while ($listener.IsListening) {
              $context  = $listener.GetContext()
              $response = $context.Response
              $msg      = [System.Text.Encoding]::UTF8.GetBytes("READY")
              $response.OutputStream.Write($msg, 0, $msg.Length)
              $response.Close()
          }
      } catch {
          Write-Warning "Failed to start readiness listener: $_"
      }

      Stop-Transcript

      # Remove scheduled task after success
      schtasks /Delete /TN "ZN-PostPromo" /F

  # --- Promotion script: executed once by Cloudbase-Init ---
  - path: C:\Windows\Temp\promote_dc.ps1
    permissions: '0644'
    content: |
      [CmdletBinding()]
      param()

      $domainFqdn = "${DOMAIN_FQDN}"
      $netbios    = "${NETBIOS_NAME}"
      $dsrmPlain  = "${DSRM_PASSWORD}"
      $adminPlain = "${ADMIN_PASSWORD}"

      $LogFile = "C:\Windows\Temp\ADDSInstall.log"
      Start-Transcript -Path $LogFile -Append
      $flagFile = "C:\Windows\Temp\PromotionComplete.txt"
      if (Test-Path $flagFile) {
          Write-Host "DC promotion already completed. Skipping..."
          exit 0
      }

      Write-Host "Promoting to new forest $domainFqdn ($netbios)..."

      # Ensure Administrator account active and password set
      net user Administrator "$adminPlain" /active:yes
      wmic useraccount where "name='Administrator'" set PasswordExpires=False | Out-Null

      # Schedule post-promotion task to start at next boot
      $action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\post_promo.ps1"
      $trigger   = New-ScheduledTaskTrigger -AtStartup
      $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
      Register-ScheduledTask -TaskName "ZN-PostPromo" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

      # Install AD DS
      Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

      $params = @{
          DomainName                    = $domainFqdn
          DomainNetbiosName             = $netbios
          SafeModeAdministratorPassword = (ConvertTo-SecureString $dsrmPlain -AsPlainText -Force)
          ForestMode                    = "WinThreshold"
          DomainMode                    = "WinThreshold"
          Force                         = $true
          NoRebootOnCompletion          = $true
      }

      Install-ADDSForest @params | Out-Null
      New-Item -ItemType File -Path $flagFile -Force | Out-Null
      Restart-Computer -Force
      Write-Host "AD DS promotion initiated, rebooting..."
      Stop-Transcript
      Restart-Computer -Force

runcmd:
  - [ powershell.exe, -NoLogo, -NoProfile, -ExecutionPolicy, Bypass, -Command, "Restart-NetAdapter -Name 'Ethernet'; Start-Sleep 5; ipconfig /renew" ]
  - [ powershell.exe, -NoLogo, -NoProfile, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\promote_dc.ps1" ]


