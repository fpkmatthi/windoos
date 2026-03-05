Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "Installing Sysinternals..."
choco install sysinternals -y
Write-Log "Sysinternals installed."
