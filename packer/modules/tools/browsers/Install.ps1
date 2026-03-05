Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "Installing browsers..."
choco install googlechrome -y
choco install firefox -y
Write-Log "Browsers installed."
