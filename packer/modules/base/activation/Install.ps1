Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

function Get-ActivationKey {
  # Priority:
  # 1) env:WINDOWS_PRODUCT_KEY
  # 2) C:\Windoos\secrets\windows_product_key.txt (optional)
  if ($env:WINDOWS_PRODUCT_KEY -and $env:WINDOWS_PRODUCT_KEY.Trim().Length -gt 0) {
    return $env:WINDOWS_PRODUCT_KEY.Trim()
  }

  $keyPath = "C:\Windoos\secrets\windows_product_key.txt"
  if (Test-Path $keyPath) {
    $k = (Get-Content -Raw -Path $keyPath).Trim()
    if ($k.Length -gt 0) { return $k }
  }

  return $null
}

Write-Log "Activation module: starting"

$key = Get-ActivationKey
if (-not $key) {
  Write-Log "Activation module: no product key provided; skipping."
  return
}

# Optional: allow KMS via env var
$kms = $env:WINDOWS_KMS_SERVER
if ($kms -and $kms.Trim().Length -gt 0) {
  $kms = $kms.Trim()
  Write-Log "Activation module: configuring KMS server (provided)"
  & cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /skms $kms | Out-Null
}

Write-Log "Activation module: installing product key (provided)"
& cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /ipk $key | Out-Null

Write-Log "Activation module: attempting activation"
& cscript.exe //Nologo C:\Windows\System32\slmgr.vbs /ato | Out-Null

Write-Log "Activation module: done (check activation state in OS if needed)"
