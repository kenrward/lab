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

      $installerCommand = ${INSTALL_SCRIPT_JSON}
      if ([string]::IsNullOrWhiteSpace($installerCommand)) {
          Write-Warning "No installer command provided."
      } else {
          $exe = $null
          $args = $null

          if ($installerCommand.StartsWith('"')) {
              $endQuote = $installerCommand.IndexOf('"', 1)
              if ($endQuote -gt 1) {
                  $exe = $installerCommand.Substring(1, $endQuote - 1)
                  $args = $installerCommand.Substring($endQuote + 1).Trim()
              }
          }

          if (-not $exe) {
              $parts = $installerCommand.Split(' ', 2)
              $exe = $parts[0]
              if ($parts.Count -gt 1) {
                  $args = $parts[1]
              }
          }

          if (Test-Path $exe) {
              try {
                  if ($args -and $args.Length -gt 0) {
                      Start-Process $exe -ArgumentList $args -Wait
                  } else {
                      Start-Process $exe -Wait
                  }
              } catch {
                  Write-Error "Installation failed: $_"
              }
          } else {
              Write-Warning "Seg installer not found at $exe"
          }
      }

      Stop-Transcript

  - path: C:\Windows\Temp\join_domain.ps1
    permissions: '0644'
    encoding: b64
    content: ${JOIN_DOMAIN_PS1_B64}

runcmd:
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\join_domain.ps1" ]
  - [ powershell.exe, -ExecutionPolicy, Bypass, -File, "C:\\Windows\\Temp\\install_seg.ps1" ]

