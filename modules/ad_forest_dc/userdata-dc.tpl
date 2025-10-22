#cloud-config
write_files:
  # --- Post-promotion script: runs after reboot as a scheduled task ---
  - path: C:\Windows\Temp\post_promo.ps1
    permissions: '0644'
    content: |
      param()
      $domainFqdn = "${DOMAIN_FQDN}"
      $adminPlain = "${ADMIN_PASSWORD}"
      $LogFile = "C:\Windows\Temp\ADDSPostPromo.log"
      Start-Transcript -Path $LogFile -Append

      # Wait for NTDS (domain service) to be up before proceeding
      $max = 60
      for ($i = 0; $i -lt $max; $i++) {
          try {
              if ((Get-Service NTDS -ErrorAction Stop).Status -eq 'Running') { break }
          } catch {}
          Start-Sleep -Seconds 5
      }

      # Ensure domain admin password
      net user Administrator "$adminPlain" /domain

      # Enable RDP
      Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
      Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' | Out-Null

      # Optional readiness port
      if (${READY_PORT} -gt 0 -and "${READY_PATH}") {
          try {
              New-Item -ItemType Directory -Path "${READY_PATH}" -Force | Out-Null
              netsh advfirewall firewall add rule name="ReadyProbe" dir=in action=allow protocol=TCP localport=${READY_PORT} | Out-Null
          } catch {}
      }

      # Self-cleanup
      schtasks /Delete /TN "ZN-PostPromo" /F
      Stop-Transcript

  # --- Promotion script: executed by Cloudbase-Init ---
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

      # Ensure hostname before promotion
      try {
          $desired = "lab-dc01"
          if ((hostname) -ne $desired) {
              Rename-Computer -NewName $desired -Force
          }
      } catch {}

      # Make sure Administrator account is active
      net user Administrator "$adminPlain" /active:yes
      wmic useraccount where "name='Administrator'" set PasswordExpires=False | Out-Null

      # Schedule post-promotion task
      $action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\post_promo.ps1"
      $trigger   = New-ScheduledTaskTrigger -AtStartup
      $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
      Register-ScheduledTask -TaskName "ZN-PostPromo" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

      # Promote to forest root domain
      Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
      $forestParams = @{
          DomainName                    = $domainFqdn
          DomainNetbiosName             = $netbios
          SafeModeAdministratorPassword = (ConvertTo-SecureString $dsrmPlain -AsPlainText -Force)
          ForestMode                    = "WinThreshold"
          DomainMode                    = "WinThreshold"
          Force                         = $true
          NoRebootOnCompletion          = $true
      }
      Install-ADDSForest @forestParams | Out-Null
      Stop-Transcript

      Restart-Computer -Force

# --- Run script as 64-bit PowerShell in background ---
runcmd:
  - [ powershell.exe, -NoLogo, -NoProfile, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\promote_dc.ps1" ]
