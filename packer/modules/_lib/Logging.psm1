function Write-Log {
  param([string]$Message)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$ts] [Windoos] $Message"
}
Export-ModuleMember -Function Write-Log
