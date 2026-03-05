Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "[Windoos] Finalize starting..."

# Cleanup Chocolatey caches
if (Get-Command choco -ErrorAction SilentlyContinue) {
  choco clean --yes | Out-Null
}

# Clear temp
Get-ChildItem "C:\Windows\Temp" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-ChildItem "$env:TEMP" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "[Windoos] Finalize complete."
