$maxTries = 12
$try = 0

while ($try -lt $maxTries) {
    $iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name -First 1
    if ($iface) {
        Write-Host "Found network interface: $iface"
        $dcIpValue = ${DC_IP_JSON}
        $dcIp = ""
        if ($dcIpValue) {
            $dcIp = $dcIpValue.Trim()
        }

        try {
            if ([string]::IsNullOrWhiteSpace($dcIp)) {
                Write-Host "No domain controller IP provided; skipping DNS configuration."
                break
            }

            Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses $dcIp
            Write-Host "DNS server set to $dcIp"
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

$readyUrlValue = ${READY_URL_JSON}
if ($readyUrlValue) {
    $readyUrl = $readyUrlValue.Trim()
} else {
    $readyUrl = ""
}

$readyPort = ${READY_PORT}
$readyPathValue = ${READY_PATH_JSON}
if ($readyPathValue) {
    $readyPath = $readyPathValue.Trim()
} else {
    $readyPath = ""
}

if (-not [string]::IsNullOrWhiteSpace($readyPath) -and -not $readyPath.StartsWith("/")) {
    $readyPath = "/" + $readyPath
}

$dcIpForUrlValue = ${DC_IP_JSON}
if ($dcIpForUrlValue) {
    $dcIpForUrl = $dcIpForUrlValue.Trim()
} else {
    $dcIpForUrl = ""
}

if ([string]::IsNullOrWhiteSpace($readyUrl) -and -not [string]::IsNullOrWhiteSpace($dcIpForUrl)) {
    $readyUrl = "http://$dcIpForUrl:$readyPort$readyPath"
}

if (-not [string]::IsNullOrWhiteSpace($readyUrl)) {
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

$domainValue = ${DOMAIN_FQDN_JSON}
if ($domainValue) {
    $domain = $domainValue.Trim()
} else {
    $domain = ""
}

$joinUserValue = ${JOIN_USERNAME_JSON}
if ($joinUserValue) {
    $joinUser = $joinUserValue.Trim()
} else {
    $joinUser = ""
}

$joinPasswordPlainValue = ${JOIN_PASSWORD_JSON}
if ($joinPasswordPlainValue) {
    $joinPasswordPlain = $joinPasswordPlainValue
} else {
    $joinPasswordPlain = $null
}

if (-not [string]::IsNullOrWhiteSpace($domain) -and -not [string]::IsNullOrWhiteSpace($joinUser) -and $joinPasswordPlain) {
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
