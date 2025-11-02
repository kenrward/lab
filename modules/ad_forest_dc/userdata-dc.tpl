#cloud-config
hostname: ${HOSTNAME}

write_files:
  - path: C:\Windows\Temp\promote_dc.ps1
    permissions: '0644'
    content: |
      [CmdletBinding()]
      param()

      $domainFqdn = "${DOMAIN_FQDN}"
      $netbios    = "${NETBIOS_NAME}"
      $dsrmPlain  = "${DSRM_PASSWORD}"
      $adminPlain = "${ADMIN_PASSWORD}"

      $flagFile  = "C:\Windows\Temp\PromotionComplete.txt"
      $LogFile   = "C:\Windows\Temp\ADDSInstall.log"
      $readyPort = 8080
      $readyPath = "C:\Windows\Temp\Ready"

      Start-Transcript -Path $LogFile -Append

      if (Test-Path $flagFile) {
          Write-Host "✅ DC promotion already completed. Starting readiness listener..."
          try {
              New-Item -ItemType Directory -Path $readyPath -Force | Out-Null
              netsh advfirewall firewall add rule name="ReadyProbe" dir=in action=allow protocol=TCP localport=$readyPort | Out-Null

              $prefix = "http://+:$readyPort/"
              Write-Host "Listening on $prefix for READY probe..."
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
          }
          catch {
              Write-Warning "⚠️ Failed to start readiness listener: $_"
          }
          Stop-Transcript
          exit 0
      }

      Write-Host "🚀 Promoting new forest: $domainFqdn ($netbios)"

      # Ensure Administrator account is active and password set
      net user Administrator "$adminPlain" /active:yes | Out-Null
      wmic useraccount where "name='Administrator'" set PasswordExpires=False | Out-Null

      # Install AD DS Role
      Write-Host "Installing AD DS role..."
      Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null

      $params = @{
          DomainName                    = $domainFqdn
          DomainNetbiosName             = $netbios
          SafeModeAdministratorPassword = (ConvertTo-SecureString $dsrmPlain -AsPlainText -Force)
          ForestMode                    = "WinThreshold"
          DomainMode                    = "WinThreshold"
          Force                         = $true
          NoRebootOnCompletion          = $true
      }

      try {
          Write-Host "Running Install-ADDSForest..."
          Install-ADDSForest @params -ErrorAction Stop | Tee-Object -FilePath $LogFile -Append
          New-Item -ItemType File -Path $flagFile -Force | Out-Null
          Write-Host "✅ AD DS promotion complete. Rebooting..."
      }
      catch {
          Write-Error "❌ AD DS promotion failed: $_"
          Stop-Transcript
          exit 1
      }

      Stop-Transcript
      Restart-Computer -Force

runcmd:
  - [ powershell.exe, -NoLogo, -NoProfile, -ExecutionPolicy, Bypass, -Command, "Restart-NetAdapter -Name 'Ethernet'; Start-Sleep 5; ipconfig /renew" ]
  - [ powershell.exe, -NoLogo, -NoProfile, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\promote_dc.ps1" ]
