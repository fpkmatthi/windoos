Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

if ($env:LAB_MODE -ne "true") {
  throw "lab/relaxed-security requires LAB_MODE=true (guardrail)."
}

Write-Log "LAB MODE: relaxed security profile selected."
Write-Log "This module is intentionally a stub. Keep lab-only changes gated + documented."
