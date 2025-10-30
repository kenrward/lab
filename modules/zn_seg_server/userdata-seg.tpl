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
      $domain = "${DOMAIN_FQDN}"
      $user = "${JOIN_USERNAME}"
      $pass = "${JOIN_PASSWORD}" | ConvertTo-SecureString -AsPlainText -Force
      $cred = New-Object System.Management.Automation.PSCredential($user, $pass)
      Add-Computer -DomainName $domain -Credential $cred -Force -ErrorAction Stop
      Restart-Computer -Force

runcmd:
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\join_domain.ps1" ]
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\install_seg.ps1" ]
