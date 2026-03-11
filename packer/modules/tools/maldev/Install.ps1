Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "Installing maldev tools..."
choco install pebear -y
choco install procmon -y
choco install systeminformer -y
Write-Log "Browsers installed."
