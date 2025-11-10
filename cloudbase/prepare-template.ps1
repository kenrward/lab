param(
  [switch]$Seal,
  [string]$UnattendPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"
)

# Set-ExecutionPolicy Bypass -Scope Process -Force
# C:\Scripts\Prepare-Template.ps1 -Seal


Write-Host "=== Template Prep: checks + fixes ==="

# Require admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  throw "Run this as Administrator."
}

# 1) VMware Tools
$vmtools = Get-Service -Name "VMTools" -ErrorAction SilentlyContinue
if (-not $vmtools) { Write-Warning "VMware Tools not found. Install before sealing." } else { Write-Host "VMware Tools: $($vmtools.Status)" }

# 2) Cloudbase-Init install + service
$cbRoot = "$env:ProgramFiles\Cloudbase Solutions\Cloudbase-Init"
if (-not (Test-Path $cbRoot)) { throw "Cloudbase-Init not installed at '$cbRoot'." }
$cbSvc = Get-Service cloudbase-init -ErrorAction Stop
# Ensure Automatic start
if ($cbSvc.StartType -ne 'Automatic') {
    Write-Host "Setting cloudbase-init startup type to Automatic..."
    Set-Service cloudbase-init -StartupType Automatic
}

# Then set DelayedAutoStart flag in registry
Write-Host "Enabling delayed auto-start for cloudbase-init..."
Set-Service cloudbase-init -StartupType AutomaticDelayedStart


# Stop before sealing (prevents it kicking during shutdown)
if ($cbSvc.Status -ne 'Stopped') {
  Write-Host "Stopping cloudbase-init..."
  Stop-Service cloudbase-init -Force -ErrorAction SilentlyContinue
}

# 3) Ensure unattend exists
if (-not (Test-Path $UnattendPath)) { throw "Unattend file missing: $UnattendPath" }

# 4) Network adapter type (warn only)
try {
  $ad = Get-NetAdapter | Where-Object Status -eq Up | Select-Object -First 1
  if ($ad -and $ad.DriverDescription -notmatch 'VMXNET3') {
    Write-Warning "Adapter is '$($ad.DriverDescription)'; VMXNET3 recommended."
  } else { Write-Host "Adapter OK: $($ad.DriverDescription)" }
} catch {}

# 5) Time zone (fix if not EST to match your unattend)
$tz = (Get-TimeZone).Id
if ($tz -ne 'Eastern Standard Time') {
  Write-Host "Setting TimeZone to Eastern Standard Time..."
  Set-TimeZone -Id 'Eastern Standard Time'
}

# 6) Activation note (non-blocking)
try {
  $lic = (Get-CimInstance -Class SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.LicenseStatus -eq 1 })
  if (-not $lic) { Write-Host "Windows not activated. KMS key recommended to avoid prompts." }
} catch {}

# 7) Windows Update: if running, STOP IT (and BITS) + disable during seal
foreach ($svc in 'wuauserv','bits') {
  $s = Get-Service $svc -ErrorAction SilentlyContinue
  if ($s) {
    if ($s.Status -ne 'Stopped') {
      Write-Host "Stopping service $svc..."
      Stop-Service $svc -Force -ErrorAction SilentlyContinue
    }
    # Put to Manual to avoid auto-restart during seal
    Write-Host "Setting $svc startup to Manual..."
    Set-Service $svc -StartupType Manual -ErrorAction SilentlyContinue
  }
}

# 8) Cleanup: Panther, Sysprep traces, temp, cb-init logs
$paths = @(
  "C:\Windows\Panther",
  "C:\Windows\System32\Sysprep\Panther",
  "C:\Windows\System32\Sysprep\Sysprep_in_progress.tag",
  "C:\Windows\System32\Sysprep\Sysprep_succeeded.tag",
  "C:\Windows\Temp\*",
  "$cbRoot\log"
)
foreach ($p in $paths) { if (Test-Path $p) { Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue } }
# Clear users' temp
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
  $t = Join-Path $_.FullName "AppData\Local\Temp"
  if (Test-Path $t) { Remove-Item -Recurse -Force "$t\*" -ErrorAction SilentlyContinue }
}

# 9) Event logs (optional but useful)
wevtutil el | ForEach-Object {
    try { wevtutil cl $_ 2>$null } catch {}
}


Write-Host "Prep complete."

if ($Seal) {
    Write-Host "Sealing with Sysprep..."
    $unatt = "$env:ProgramFiles\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"
    & "$env:WINDIR\System32\Sysprep\sysprep.exe" /generalize /oobe /shutdown /unattend:"$unatt"
    Write-Host "Sysprep complete. Machine will shut down. Convert to template and do not power on."
} else {
    Write-Host "Dry run done. Re-run with -Seal to execute Sysprep automatically."
}
