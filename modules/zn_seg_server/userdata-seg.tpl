#cloud-config
hostname: ${HOSTNAME}

write_files:
  - path: C:\Windows\Temp\install_seg.ps1
    permissions: '0644'
    content: |
      [CmdletBinding()]
      param()

      $log = "C:\Windows\Temp\SegInstall.log"
      Start-Transcript -Path $log -Append
      Write-Host "Starting SegServer application install..."

      # Example installer section
      try {
          if (Test-Path "C:\Installers\SegSetup.exe") {
              Start-Process "C:\Installers\SegSetup.exe" -ArgumentList "/quiet /norestart" -Wait
          } else {
              Write-Warning "Seg installer not found at C:\Installers\SegSetup.exe"
          }
      } catch {
          Write-Error "Installation failed: $_"
      }

      Stop-Transcript

  - path: C:\Windows\Temp\join_domain.ps1
    permissions: '0644'
    content: |
      [CmdletBinding()]
      param()

      $LogFile = "C:\Windows\Temp\join_domain.log"
      Start-Transcript -Path $LogFile -Append

      Write-Host "=== Domain Join Script Starting ==="

      # --- Ensure Administrator password is set and login flags cleared ---
      try {
          Write-Host "Setting local Administrator password..."
          $adminUser = "Administrator"
          $adminPass = ConvertTo-SecureString "${ADMIN_PASSWORD}" -AsPlainText -Force
          Set-LocalUser -Name $adminUser -Password $adminPass
          Set-LocalUser -Name $adminUser -PasswordNeverExpires $true
          wmic useraccount where "name='$adminUser'" set PasswordExpires=FALSE | Out-Null
          Write-Host "Administrator password set and expiration cleared."
      } catch {
          Write-Host "Warning: Could not set Administrator password - $_"
      }

      # --- Wait for network interface and set DNS ---
      $maxTries = 12
      for ($try = 1; $try -le $maxTries; $try++) {
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
              Write-Host "Network interface not ready, waiting ($try/$maxTries)..."
              Start-Sleep -Seconds 10
          }
      }

      # --- Check if already domain-joined ---
      $domain = "${DOMAIN_FQDN}"
      $currentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
      if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain -and ($currentDomain -ieq $domain)) {
          Write-Host "Machine is already joined to $currentDomain, skipping domain join."
      } else {
          try {
              Write-Host "Joining domain $domain..."
              $user = "${JOIN_USERNAME}"
              $pass = ConvertTo-SecureString "${JOIN_PASSWORD}" -AsPlainText -Force
              $cred = New-Object System.Management.Automation.PSCredential ($user, $pass)
              Add-Computer -DomainName $domain -Credential $cred -Force -ErrorAction Stop
              Write-Host "Successfully joined domain $domain."
          } catch {
              Write-Host "Domain join failed: $_"
          }
      }

      # --- Wait briefly to let Cloudbase-Init finalize ---
      Write-Host "Waiting for Cloudbase-Init to finalize..."
      Start-Sleep -Seconds 30

      Write-Host "=== Domain Join Script Completed ==="
      Stop-Transcript

runcmd:
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\join_domain.ps1" ]
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\install_seg.ps1" ]

