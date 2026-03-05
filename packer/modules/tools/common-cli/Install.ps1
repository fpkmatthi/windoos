Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "Installing common CLI tools..."
choco install jq -y
choco install ripgrep -y
Write-Log "Common CLI tools installed."
