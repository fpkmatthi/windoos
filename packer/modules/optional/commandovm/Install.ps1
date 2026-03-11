Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Import-Module "C:\Windoos\modules\_lib\Logging.psm1" -Force

Write-Log "CommandoVM module placeholder."
Write-Log "Implement your approved installation method here (internal mirror recommended)."

# Disable defender
# Run as Administrator
# NOTE: If Tamper Protection is ON, Windows may block some of these changes.

$ErrorActionPreference = "Stop"

$LogPath = "C:\Windows\Temp\disable-defender.log"
Start-Transcript -Path $LogPath -Append | Out-Null

function Write-Step($msg) { Write-Host "==> $msg" }

try {
    Write-Step "Disabling TamperProtection"
    Set-MpPreference -DisableTamperProtection $true

    Write-Step "Setting execution policy for this process"
    Set-ExecutionPolicy Bypass -Scope Process -Force

    Write-Step "Creating Defender policy registry keys (Group Policy equivalent)"
    $wdPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    New-Item -Path $wdPolicy -Force | Out-Null

    # Primary "turn off Defender" policy
    # (Microsoft has deprecated some of these in newer builds, but they still help / are used in many orgs)
    New-ItemProperty -Path $wdPolicy -Name "DisableAntiSpyware" -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $wdPolicy -Name "DisableAntiVirus"    -PropertyType DWord -Value 1 -Force | Out-Null

    # Real-time protection policy keys
    $rtp = Join-Path $wdPolicy "Real-Time Protection"
    New-Item -Path $rtp -Force | Out-Null
    New-ItemProperty -Path $rtp -Name "DisableRealtimeMonitoring"        -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $rtp -Name "DisableBehaviorMonitoring"        -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $rtp -Name "DisableOnAccessProtection"        -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $rtp -Name "DisableScanOnRealtimeEnable"      -PropertyType DWord -Value 1 -Force | Out-Null

    # SpyNet / cloud submission policies
    $spynet = Join-Path $wdPolicy "Spynet"
    New-Item -Path $spynet -Force | Out-Null
    # 0 = Disabled reporting, 2 = Advanced (values vary by build; 0 is safest to reduce cloud interactions)
    New-ItemProperty -Path $spynet -Name "SpyNetReporting"               -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $spynet -Name "SubmitSamplesConsent"          -PropertyType DWord -Value 2 -Force | Out-Null

    Write-Step "Attempting to disable Defender preferences (best-effort)"
    # These may fail if Tamper Protection is enabled; treat as best-effort.
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true
        Set-MpPreference -DisableBehaviorMonitoring $true
        Set-MpPreference -DisableIOAVProtection $true
        Set-MpPreference -DisableBlockAtFirstSeen $true
        Set-MpPreference -DisableArchiveScanning $true
        Set-MpPreference -DisableScriptScanning $true
        Set-MpPreference -MAPSReporting 0
        Set-MpPreference -SubmitSamplesConsent 2
    } catch {
        Write-Host "WARN: Set-MpPreference blocked/failed (Tamper Protection likely ON): $($_.Exception.Message)"
    }

    Write-Step "Disabling SmartScreen (optional, but often helpful for lab images)"
    try {
        $sysPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        New-Item -Path $sysPol -Force | Out-Null
        New-ItemProperty -Path $sysPol -Name "EnableSmartScreen" -PropertyType DWord -Value 0 -Force | Out-Null

        $edgeSS = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter"
        New-Item -Path $edgeSS -Force | Out-Null
        New-ItemProperty -Path $edgeSS -Name "EnabledV9" -PropertyType DWord -Value 0 -Force | Out-Null
    } catch {
        Write-Host "WARN: SmartScreen policy set failed: $($_.Exception.Message)"
    }

    Write-Step "Disabling Defender scheduled tasks (best-effort)"
    $tasks = @(
        "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance",
        "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup",
        "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan",
        "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
    )

    foreach ($t in $tasks) {
        try {
            schtasks /Change /TN $t /Disable | Out-Null
        } catch {
            Write-Host "WARN: Failed to disable task $t : $($_.Exception.Message)"
        }
    }

    Write-Step "Applying policy update"
    try { gpupdate /force | Out-Null } catch { Write-Host "WARN: gpupdate failed: $($_.Exception.Message)" }

    Write-Step "Attempting to stop Defender services (best-effort)"
    foreach ($svc in @("WinDefend","WdNisSvc","Sense")) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        } catch {
            Write-Host "WARN: Could not stop/disable service $svc : $($_.Exception.Message)"
        }
    }

    Write-Step "Verification (best-effort)"
    try {
        $status = Get-MpComputerStatus
        $status | Select-Object AMRunningMode, RealTimeProtectionEnabled, AntivirusEnabled, AntispywareEnabled | Format-List
    } catch {
        Write-Host "INFO: Get-MpComputerStatus not available / blocked: $($_.Exception.Message)"
    }

    Write-Step "Done. A reboot is recommended to fully apply policies."
}
finally {
    Stop-Transcript | Out-Null
    Write-Host "Log written to: $LogPath"
}


# Run as Administrator
Write-Host "Starting Commando VM installation..."

# Ensure TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow scripts to run in this session
Set-ExecutionPolicy Bypass -Scope Process -Force

# Create working directory
$installDir = "C:\commando-vm"

if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

cd $installDir

# Download Commando VM repository
Write-Host "Downloading Commando VM..."

$zipUrl = "https://github.com/mandiant/commando-vm/archive/refs/heads/main.zip"
$zipFile = "$installDir\commando-vm.zip"

Invoke-WebRequest $zipUrl -OutFile $zipFile

# Extract files
Write-Host "Extracting files..."
Expand-Archive $zipFile -DestinationPath $installDir -Force

# Move into extracted directory
$repoDir = Get-ChildItem $installDir -Directory | Where-Object { $_.Name -like "commando-vm*" } | Select-Object -First 1
cd $repoDir.FullName

# Unblock scripts
Write-Host "Unblocking scripts..."
Get-ChildItem . -Recurse | Unblock-File

# Start installation (CLI mode recommended for automation)
Write-Host "Launching Commando VM installer..."
Set-ExecutionPolicy Unrestricted -Force
.\install.ps1
