Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "Installing devtools (vscode, curl, openssh)..."

choco install vscode -y
choco install curl -y
choco install openssh -y

Write-Log "Devtools installed."
