Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "Installing base runtimes (7zip, git, pwsh, python)..."

choco install 7zip -y
choco install git -y
choco install powershell-core -y
choco install python -y

Write-Log "Base runtimes installed."
