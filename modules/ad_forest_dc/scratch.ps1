# Install-ADDSForest.ps1
      # Configures a new Active Directory Domain Services Forest on Windows Server 2022
      
      # Environment Variables (Passed in via cloud-init)
      $domainFqdn   = "${DOMAIN_FQDN}"
      $netbios      = "${NETBIOS_NAME}"
      $dsrmPlain    = "${DSRM_PASSWORD}"
      $adminPlain   = "${ADMIN_PASSWORD}"
      $readyPort    = ${READY_PORT}
      $readyPath    = "${READY_PATH}"
      
      # Convert passwords to SecureString
      $SafeModeAdminPassword = ConvertTo-SecureString $dsrmPlain -AsPlainText -Force
      $ForestMode = "WinThreshold"  # Windows Server 2016+ forest functional level
      $DomainMode = "WinThreshold"  # Windows Server 2016+ domain functional level
      
      # Logging
      $LogFile = "C:\Windows\Setup\Logs\ADDSInstall.log"
      New-Item -ItemType Directory -Path "C:\Windows\Setup\Logs" -Force -ErrorAction SilentlyContinue
      Start-Transcript -Path $LogFile -Append
      
      Write-Host "========================================" -ForegroundColor Cyan
      Write-Host "AD DS Forest Installation Started" -ForegroundColor Cyan
      Write-Host "Time: $(Get-Date)" -ForegroundColor Cyan
      Write-Host "Domain: $domainFqdn" -ForegroundColor Cyan
      Write-Host "NetBIOS: $netbios" -ForegroundColor Cyan
      Write-Host "========================================" -ForegroundColor Cyan
      
      try {
          # Install AD DS Role and Management Tools
          Write-Host "`n[1/5] Installing AD DS Role and Management Tools..." -ForegroundColor Yellow
          $addsInstall = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Verbose
          
          if ($addsInstall.Success) {
              Write-Host "✓ AD DS Role installed successfully" -ForegroundColor Green
          } else {
              throw "AD DS Role installation failed: $($addsInstall.ExitCode)"
          }
          
          # Install DNS Server (required for AD DS)
          Write-Host "`n[2/5] Installing DNS Server Role..." -ForegroundColor Yellow
          $dnsInstall = Install-WindowsFeature -Name DNS -IncludeManagementTools -Verbose
          
          if ($dnsInstall.Success) {
              Write-Host "✓ DNS Server Role installed successfully" -ForegroundColor Green
          } else {
              throw "DNS Server installation failed: $($dnsInstall.ExitCode)"
          }
          
          # Configure DNS forwarders (using common public DNS)
          Write-Host "`n[3/5] Configuring DNS forwarders..." -ForegroundColor Yellow
          try {
              Add-DnsServerForwarder -IPAddress "8.8.8.8" -PassThru | Out-Null
              Add-DnsServerForwarder -IPAddress "8.8.4.4" -PassThru | Out-Null
              Add-DnsServerForwarder -IPAddress "1.1.1.1" -PassThru | Out-Null
              Write-Host "✓ DNS forwarders configured" -ForegroundColor Green
          } catch {
              Write-Host "⚠ DNS forwarders configuration warning: $_" -ForegroundColor Yellow
          }
          
          # Install the new AD DS Forest
          Write-Host "`n[4/5] Installing new AD DS Forest: $domainFqdn" -ForegroundColor Yellow
          Write-Host "This will take several minutes and the server will reboot automatically..." -ForegroundColor Yellow
          
          Install-ADDSForest `
              -DomainName $domainFqdn `
              -DomainNetbiosName $netbios `
              -ForestMode $ForestMode `
              -DomainMode $DomainMode `
              -InstallDns:$true `
              -CreateDnsDelegation:$false `
              -DatabasePath "C:\Windows\NTDS" `
              -LogPath "C:\Windows\NTDS" `
              -SysvolPath "C:\Windows\SYSVOL" `
              -SafeModeAdministratorPassword $SafeModeAdminPassword `
              -NoRebootOnCompletion:$false `
              -Force:$true `
              -Verbose
          
          Write-Host "`n✓ AD DS Forest installation completed successfully" -ForegroundColor Green
          Write-Host "Server will reboot in 10 seconds..." -ForegroundColor Yellow
          
      } catch {
          Write-Host "`n✗ ERROR during AD DS installation" -ForegroundColor Red
          Write-Host "Error: $_" -ForegroundColor Red
          Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Red
          Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
          Stop-Transcript
          exit 1
      }
      
      Stop-Transcript
      # Server will automatically reboot after forest installation