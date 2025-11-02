#cloud-config
hostname: ${HOSTNAME}

write_files:
  - path: C:\Windows\Temp\join_domain.ps1
    encoding: b64
    content: ${JOIN_DOMAIN_PS1_B64}

runcmd:
  - powershell.exe -ExecutionPolicy Bypass -File C:\Windows\Temp\join_domain.ps1
