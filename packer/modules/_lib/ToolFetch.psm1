Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-DownloadFile {
  param(
    [Parameter(Mandatory=$true)][string]$Url,
    [Parameter(Mandatory=$true)][string]$OutFile
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
}

function Assert-FileHash {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$ExpectedSha256
  )
  $h = (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLowerInvariant()
  if ($h -ne $ExpectedSha256.ToLowerInvariant()) {
    throw "SHA256 mismatch for $Path. Expected $ExpectedSha256, got $h"
  }
}

Export-ModuleMember -Function Invoke-DownloadFile, Assert-FileHash
