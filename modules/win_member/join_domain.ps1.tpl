$maxTries = 12
$try = 0
$dcIp = ${DC_IP_JSON}
$dcIpTrimmed = ""
if ($dcIp) {
    $dcIpTrimmed = $dcIp.Trim()
}

while ($try -lt $maxTries) {
    $iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name -First 1
    if ($iface) {
        Write-Host "Found network interface: $iface"
        if ($dcIpTrimmed.Length -gt 0) {
            try {
                Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses $dcIpTrimmed
                Write-Host "DNS server set to $dcIpTrimmed"
                break
            } catch {
                Write-Host "Failed to set DNS: $_"
            }
        } else {
            Write-Host "No domain controller IP provided; skipping DNS configuration."
            break
        }
    } else {
        Write-Host "Network interface not ready, waiting..."
    }
    Start-Sleep -Seconds 10
    $try++
}

$readyUrl = ${READY_URL_JSON}
$readyPort = ${READY_PORT}
$readyPath = ${READY_PATH_JSON}

if ($readyPath) {
    $readyPath = $readyPath.Trim()
    if ($readyPath.Length -gt 0 -and -not $readyPath.StartsWith("/")) {
        $readyPath = "/" + $readyPath
    }
} else {
    $readyPath = ""
}

if ($readyUrl) {
    $readyUrl = $readyUrl.Trim()
} else {
    $readyUrl = ""
}

if ($readyUrl.Length -eq 0 -and $dcIpTrimmed.Length -gt 0) {
    $readyUrl = "http://$dcIpTrimmed:$readyPort$readyPath"
}

if ($readyUrl.Length -gt 0) {
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

$domain = ${DOMAIN_FQDN_JSON}
if ($domain) {
    $domain = $domain.Trim()
} else {
    $domain = ""
}

$joinUser = ${JOIN_USERNAME_JSON}
if ($joinUser) {
    $joinUser = $joinUser.Trim()
} else {
    $joinUser = ""
}

$joinPasswordPlain = ${JOIN_PASSWORD_JSON}

if ($domain.Length -gt 0 -and $joinUser.Length -gt 0 -and $joinPasswordPlain) {
    try {
        $securePass = ConvertTo-SecureString $joinPasswordPlain -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($joinUser, $securePass)
        Add-Computer -DomainName $domain -Credential $cred -Force -ErrorAction Stop
        Write-Host "Successfully joined domain."
    } catch {
        Write-Host "Domain join failed: $_"
    }
} else {
    Write-Warning "Missing domain join parameters; skipping domain join."
}

Write-Host "Rebooting in 10 seconds..."
Start-Sleep -Seconds 10
Restart-Computer -Force
