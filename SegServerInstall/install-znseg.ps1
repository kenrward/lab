#update 4.0
[CmdletBinding()]
param(

    # Token to use to install the Cloud Connector
    [Parameter(Mandatory = $False)]
    [String]$SegInstallToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtOjYxOTc2NjFjYjI2YTQ1ODY5Y2NhNmM3OGJhYTJlOTEzYjQ4OWY0ZDMiLCJuYW1lIjoic2VnbWVudC1zZXJ2ZXItc2V0dXBfMTc2MjgyNTgxODAyNCIsImVpZCI6IjQ5NTU0NzYwLWE2NDgtNDA0MC04NGY2LWUyYTk4MGQxZDRjNyIsInNjb3BlIjoxMiwiZV9uYW1lIjoiQ0UtS2VuLUxhYi1BdXRvbWFpb24iLCJ2IjoyLCJpYXQiOjE3NjI4MjU4MTgsImV4cCI6MTc2Mjg1ODIxOCwiYXVkIjoiY2VrbGFiLXJlZ2lzdGVyLXNlZ21lbnQtc2VydmVyLnplcm9uZXR3b3Jrcy5jb20iLCJpc3MiOiJ6ZXJvbmV0d29ya3MuY29tL2FwaS92MS9hY2Nlc3MtdG9rZW4ifQ.W3i028QhHwJqd0zUuqkWTs47Csmugps3jEr7moRRbnR6EpjaU-VtGaF0qjDpcL9Pn27LkFVv-vq7iyUEhicxfpjx3vDM8q9n1y7Y3PjTDbPIrfiCZGYAR_ubjUo5x5Bt6NQVKnkHD_dgxduuja9kfgaFs7-yJqZH3ZD2_Pe0ipaY0dCmzNL51GiZcjkDGL7ixSMJ3hvS4sx9ro8mExMpOJmpRKDshNC2mlW4LC9qv5V7zhng-mbZnbWHUH2kLHRJeX7O8qpLhq8gZoqEtha1aBIsCamciuaQn97Mu5nnOw8LTf6dTZScpuHLpPBS2stAr_fOszenn1lENeE89TLnRw",
    [Parameter(Mandatory = $False)]
    [String]$APIToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtOmNlOGM2MTk4NzczYTllN2FjNWUxODYyZGM5MDU5N2E2MTUwNzM0MjAiLCJuYW1lIjoiVEYiLCJlaWQiOiI0OTU1NDc2MC1hNjQ4LTQwNDAtODRmNi1lMmE5ODBkMWQ0YzciLCJzY29wZSI6NCwiZV9uYW1lIjoiQ0UtS2VuLUxhYi1BdXRvbWFpb24iLCJ2IjoyLCJpYXQiOjE3NjI4MjU4NDYsImV4cCI6MTgyNTg5Nzg0NCwiYXVkIjoiY2VrbGFiLWFkbWluLnplcm9uZXR3b3Jrcy5jb20iLCJpc3MiOiJ6ZXJvbmV0d29ya3MuY29tL2FwaS92MS9hY2Nlc3MtdG9rZW4ifQ.LRddUS3SKPiyqFYyUQBy6Hva1Baq7IaklusBq86pUwu6d40DugSmZFdrcmCCwiOvPjHPKPx70-X_N49vmmChD-YsJTdwGEjnzxkCYHiOuBciammVrpvjHvFapkyLiV9PmQEM2wrDI4L4oPQ6ivP01l26IIgHCIMhv_3ZhOyBNV4doGvfbJRx8tq2MKwoRaIpGgxzBZz6YqA9OVjzNx6o_v2VMKfuSVOJ2ykvlhUXk6Yy4LN9uZWv28OJTqD9L4ZgEDvMKevekXTuvrP-c6XIXDgQL1pdRK99XOPmf4Heac1vgf0LpWo-jtCjO5FC1qhhloI__NPqdK8d-mtbZQ0Bmw",
    [Parameter(Mandatory = $False)]
    [String]$domain = "lab.local",
    [Parameter(Mandatory = $False)]
    [String]$dcfqdn = "kne-tflab-dc01.lab.local",
    [Parameter(Mandatory = $False)]
    [String]$znuser = "znremoteadmin",
    [Parameter(Mandatory = $False)]
    [String]$znpass = "1234Ootball.",
    [Parameter(Mandatory = $False)]
    [System.Boolean]$skipad = "$false",
    [Parameter(Mandatory = $False)]
    [System.Boolean]$linkGPO = "$true",
    [Parameter(Mandatory = $False)]
    [String]$ou = "OU=ZeroNetworks,DC=lab,DC=local"
)
<#
-domain": "str"
-dc-fqdn: "str"
-zn-user: "str"
-password: "str"
-skip_ad_prerequsite: bool, #default
-link_gpo: bool #defult
-ou_dn: "str" #default

# Extract Aud from JWT to find cloud connector URL.
# Your JWT token
$jwt = $SegInstallToken

# Split the JWT into its parts
$parts = $jwt -split '\.'

if ($parts.Count -ne 3) {
    throw "Invalid JWT format"
}

# Decode the payload (second part) from Base64URL
$payload = $parts[1]
$remainder = $payload.Length % 4
if ($remainder -ne 0) {
    $payload += '=' * (4 - $remainder)
}
$payload = $payload.Replace('-', '+').Replace('_', '/')
$bytes = [Convert]::FromBase64String($payload)
$json = [System.Text.Encoding]::UTF8.GetString($bytes)

# Convert to a PowerShell object
$payloadObj = $json | ConvertFrom-Json

# Extract the 'aud' field
$audience = $payloadObj.aud
#>
#Check Powershell version
$pwshVersion = $PSVersionTable.PSVersion

if ($pwshVersion.Major -ge 6) {
    # PowerShell Core or newer - UseBasicParsing is not supported
    $useBasicParsing = $false
} else {
    # Windows PowerShell (e.g., 5.1) - UseBasicParsing is supported
    $useBasicParsing = $true
}

# Logging function
$logFile = "$env:TEMP\ZNSegInstall.log"
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] [$Level] $Message"
}
Write-Log -Message "Script execution started."

if ($SegInstallToken -eq "<INSERT_SEG_TOKEN>") {
    Write-Log -Message "Cloud Connector Token is required for installation but not provided." -Level "ERROR"
    exit
}

# Define installer arguments
$installerArgs = "-$CloudConnectorFunction -token $SegInstallToken -silent -domain $domain -dc-fqdn $dcfqdn -zn-user $znuser -password $znpass -skip_ad_prerequsite $skipad -link_gpo $linkGPO  -ou_dn $ou"
# Set up headers for API request
$znHeaders = @{
    "Authorization" = $APIToken
    "Content-Type"  = "application/json"
}

# API request for download URL

$installerUri = "https://$audience/api/v1/download/segment/server"

$installerUri = "https://zncustlabs-admin.zeronetworks.com/api/v1/download/segment/server"

if ($useBasicParsing) {
    $response = Invoke-WebRequest -Uri $installerUri -Method GET -Headers $znHeaders -UseBasicParsing -ErrorAction Stop
} else {
    $response = Invoke-WebRequest -Uri $installerUri -Method GET -Headers $znHeaders -ErrorAction Stop
}
if ($response.StatusCode -ne 200) {
    Write-Log -Message "Failed to retrieve the download URL. HTTP Status Code: $($response.StatusCode)" -Level "ERROR"
    exit
}

# Parse the response
[string]$downloadUrl = ($response.Content | ConvertFrom-Json).url
if (-not $downloadUrl) {
    Write-Log -Message "Download URL is missing in the API response." -Level "ERROR"
    exit
}

# Download the installer
$fileName = "znSeg-Installer"
$zipPath = "$env:TEMP\$fileName.zip"
try {
    Invoke-WebRequest -Uri $downloadUrl -Method GET -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
    Write-Log -Message "Installer downloaded successfully."
} catch {
    Write-Log -Message "Failed to download the installer: $_" -Level "ERROR"
    exit
}

# Extract the zip file
$installerFolderPath = "$env:TEMP\$fileName"
try {
    Expand-Archive -Path $zipPath -DestinationPath $installerFolderPath -Force -ErrorAction Stop
    Write-Log -Message "Installer extracted successfully."
} catch {
    Write-Log -Message "Failed to extract the installer: $_" -Level "ERROR"
    exit
}

# Locate the installer executable
$installerFile = Get-ChildItem -Path "$installerFolderPath" -Filter "Trust-Setup.exe" -Recurse -ErrorAction Stop
if (-not $installerFile) {
    Write-Log -Message "Installer executable not found in the extracted files." -Level "ERROR"
    exit
}

# Run the installer
try {
    Start-Process -FilePath $installerFile.FullName -Wait -ArgumentList $installerArgs -WindowStyle Hidden
    Write-Log -Message "Installer executed successfully."
} catch {
    Write-Log -Message "Failed to execute the installer: $_" -Level "ERROR"
    exit
}

#Tail setup log
$setupLogPath = "$env:LOCALAPPDATA\ZeroNetworks\logs\setup.log"
if (Test-Path -Path $setupLogPath) {
    $setupText = Get-Content $setupLogPath  -Tail 1
    Write-Log -Message "CloudConnector Log Output: $setupText" 
}

# Clean up temporary files
try {
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $installerFolderPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log -Message "Temporary files cleaned up successfully."
} catch {
    Write-Log -Message "Failed to clean up temporary files: $_" -Level "WARNING"
}

# Handle uninstallation-specific tasks
if ($CloudConnectorFunction -eq "uninstall") {
    $systempath = 'C:\Windows\System32\config\systemprofile\AppData\Local\ZeroNetworks'
    $count = 0
    while ($count -lt 5) {
        Start-Sleep -Seconds 2
        $count++
        if (-not (Get-Service -Name 'zncloudconnector' -ErrorAction SilentlyContinue).Status -eq 'Running') {
            break
        }
    }
    if ((Test-Path $systempath -ErrorAction SilentlyContinue)) {
        try {
            Remove-Item -Path $systempath -Recurse -Force -ErrorAction Stop
            Write-Log -Message "Cloud Connector system files cleaned up successfully."
        } catch {
            Write-Log -Message "Failed to remove Cloud Connector system files: $_" -Level "WARNING"
        }
    }
}

Write-Log -Message "Script execution completed successfully."
