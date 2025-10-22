#cloud-config
write_files:
  - path: C:\Windows\Temp\join_domain.ps1
    permissions: "0644"
    content: |
      [CmdletBinding()]
      param()

      $ErrorActionPreference = "Stop"
      $Log = "C:\Windows\Temp\join_domain.log"
      function Log($m){ (Get-Date -Format o) + " " + $m | Add-Content $Log }

      $DomainFqdn = "${DOMAIN_FQDN}"         # e.g. lab.local
      $DcIp       = "${DC_IP}"               # from Terraform output
      $User       = "${JOIN_USERNAME}"       # e.g. LAB\Administrator or LAB\Joiner
      $Pass       = "${JOIN_PASSWORD}"

      Log "Set DNS to DC at $DcIp"
      $if = Get-NetAdapter | Where-Object Status -eq Up | Select-Object -First 1
      if ($if) {
        try {
          Set-DnsClientServerAddress -InterfaceIndex $if.ifIndex -ServerAddresses $DcIp -ErrorAction Stop
        } catch { Log "WARN: DNS set failed: $($_.Exception.Message)" }
      } else {
        Log "WARN: no Up adapter; continuing"
      }

      # Wait for LDAP on the DC (389) so we know promotion finished
      Log "Wait for LDAP on $DcIp:389"
      for ($i=1; $i -le 180; $i++){
        $ok = (Test-NetConnection -ComputerName $DcIp -Port 389 -InformationLevel Quiet)
        if ($ok){ break }
        Start-Sleep -Seconds 5
      }

      Log "Join domain $DomainFqdn"
      $sec  = ConvertTo-SecureString $Pass -AsPlainText -Force
      $cred = New-Object pscredential($User, $sec)
      Add-Computer -DomainName $DomainFqdn -Credential $cred -ErrorAction Stop

      Log "Rebooting after domain join"
      Restart-Computer -Force

runcmd:
  - [powershell, "-ExecutionPolicy", "Bypass", "-File", "C:\\Windows\\Temp\\join_domain.ps1"]
