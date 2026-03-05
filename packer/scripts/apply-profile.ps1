Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$profileName = $env:WINDOOS_PROFILE
if (-not $profileName) { throw "WINDOOS_PROFILE not set" }

$root = "C:\Windoos"
$profilesDir = Join-Path $root "profiles"
$modulesDir  = Join-Path $root "modules"

Write-Host "[Windoos] Applying profile: $profileName"

# YAML parsing
if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
  try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module powershell-yaml -Force -Scope AllUsers -SkipPublisherCheck
  } catch {
    throw "No ConvertFrom-Yaml and failed to install powershell-yaml"
  }
}

# Choco
if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
    Write-Host "Chocolatey already installed"
} else {
  try {
    Write-Host "Installing Chocolatey..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = 3072

    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  } catch {
    throw "Installation of Choco failed"
  }
}

$profilePath = Join-Path $profilesDir "$profileName.yaml"
if (-not (Test-Path $profilePath)) { throw "Profile not found: $profilePath" }

$cfg = (Get-Content -Raw $profilePath) | ConvertFrom-Yaml
if (-not $cfg.modules) { throw "Profile must contain 'modules:' list" }

foreach ($m in $cfg.modules) {
  $moduleScript = Join-Path $modulesDir $m
  $moduleScript = Join-Path $moduleScript "Install.ps1"
  Write-Host "[Windoos] Module: $m"
  if (-not (Test-Path $moduleScript)) { throw "Missing module script: $moduleScript" }
  & $moduleScript
}
