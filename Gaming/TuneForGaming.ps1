<#
.SYNOPSIS
    Streamlines a mounted offline Windows 11 image into a high-performance gaming environment.
.DESCRIPTION
    Mounts and modifies offline registry hives to remove enterprise infrastructure, 
    disable security virtualization, optimize power states, and apply low-latency tweaks.
.PARAMETER MountPath
    The absolute path to the directory where your Windows WIM/VHDX image is currently mounted.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$MountPath
)

# 1. Validate Mount Path and Locate Hives
if (-not (Test-Path "$MountPath\Windows\System32\config\SYSTEM")) {
    Write-Error "[-] Invalid Mount Path. Could not locate offline registry hives."
    Exit
}

Write-Host "[*] Mounting offline registry hives from: $MountPath" -ForegroundColor Cyan
$RegPaths = @{
    SYS  = "$MountPath\Windows\System32\config\SYSTEM"
    SOFT = "$MountPath\Windows\System32\config\SOFTWARE"
    DEF  = "$MountPath\Users\Default\NTUSER.DAT"
}

# Mount hives into local Reg provider
reg load HKLM\OFFLINE_SYSTEM $RegPaths.SYS | Out-Null
reg load HKLM\OFFLINE_SOFTWARE $RegPaths.SOFT | Out-Null
reg load HKEY_USERS\OFFLINE_DEFAULT $RegPaths.DEF | Out-Null

# 2. Disable Enterprise-Specific Background Services & Features
Write-Host "[*] Disabling Enterprise infrastructure & background auditing..." -ForegroundColor Cyan

# Service Start Types: 4 = Disabled (REG_DWORD)
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Services\DPS" /v "Start" /t REG_DWORD /d 4 /f | Out-Null
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Services\TrkWks" /v "Start" /t REG_DWORD /d 4 /f | Out-Null

# Disable WDAC / Smart App Control overhead
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\CI\Policy" /v "VerifiedAndReputablePolicyState" /t REG_DWORD /d 0 /f | Out-Null

# Disable Telemetry and Cloud Experience
reg add "HKLM\OFFLINE_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKLM\OFFLINE_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 0 /f | Out-Null

# 3. Standard Pro-Gaming Optimizations (Applies to Default User Profile)
Write-Host "[*] Injecting Windows 11 Gaming Features into Default User hive..." -ForegroundColor Cyan

# Force Game Mode Active
reg add "HKEY_USERS\OFFLINE_DEFAULT\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f | Out-Null

# Activate Hardware-Accelerated GPU Scheduling (HAGS)
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f | Out-Null

# Enable Optimizations for Windowed/Borderless Games
reg add "HKEY_USERS\OFFLINE_DEFAULT\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalFlags" /t REG_DWORD /d 2 /f | Out-Null

# Disable background GameDVR
reg add "HKEY_USERS\OFFLINE_DEFAULT\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKEY_USERS\OFFLINE_DEFAULT\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "HistoricalCaptureEnabled" /t REG_DWORD /d 0 /f | Out-Null

# 4. Disable Core Isolation & Virtualization-Based Security (VBS)
Write-Host "[*] Disabling CPU-heavy Virtualization Security offline..." -ForegroundColor Cyan

# Disable HVCI / Memory Integrity
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null

# Disable Virtualization-Based Security completely
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f | Out-Null

# Terminate High-Overhead WMI Event Tracing Logs
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\WMI\Autologger\WdiContextLog" /v "Start" /t REG_DWORD /d 0 /f | Out-Null

# 5. Inject Pro-Tier Performance Power Management
Write-Host "[*] Injecting Performance power configurations..." -ForegroundColor Cyan

# Force high performance power schemes as active default via registry (REG_SZ String)
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\Power" /v "PreferredPlan" /t REG_SZ /d "e9a42b02-d5df-448d-aa00-03f14749eb61" /f | Out-Null

# Disable CPU Core Parking under default control set profiles
reg add "HKLM\OFFLINE_SYSTEM\ControlSet001\Control\Power\PowerSettings\545335f2-2ea7-422f-a17d-875227351304\866034dc-aa47-49ef-9840-406333e68553" /v "Value" /t REG_DWORD /d 0 /f | Out-Null

# 6. Low-Latency Network Tuning
Write-Host "[*] Tuning network stack for low-latency..." -ForegroundColor Cyan

# Network Throttling Index Overrides
reg add "HKLM\OFFLINE_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f | Out-Null
reg add "HKLM\OFFLINE_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f | Out-Null

# Scan offline interfaces and inject Nagle's Algorithm bypass parameters
# Note: Since reg add requires an exact path, we still use PowerShell to loop through the unpredictable interface GUID subkeys, then execute reg add inside the loop.
$InterfacesPath = "HKLM\OFFLINE_SYSTEM\ControlSet001\Services\Tcpip\Parameters\Interfaces"
if (Test-Path "HKLM:\OFFLINE_SYSTEM\ControlSet001\Services\Tcpip\Parameters\Interfaces") {
    Get-ChildItem -Path "HKLM:\OFFLINE_SYSTEM\ControlSet001\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
        # Extract just the GUID component out of the full PowerShell provider path
        $GuidName = $_.PSChildName
        reg add "$InterfacesPath\$GuidName" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f | Out-Null
        reg add "$InterfacesPath\$GuidName" /v "TCPNoDelay" /t REG_DWORD /d 1 /f | Out-Null
    }
}

# 7. Safely Unload Registry Hives
Write-Host "`n[*] Unloading registry hives and saving changes..." -ForegroundColor Cyan
[gc]::collect()
reg unload HKLM\OFFLINE_SYSTEM | Out-Null
reg unload HKLM\OFFLINE_SOFTWARE | Out-Null
reg unload HKEY_USERS\OFFLINE_DEFAULT | Out-Null

Write-Host "[✓] Offline integration complete! Disposed hive links safely." -ForegroundColor Green
Write-Host "[!] You may now commit your changes using DISM (dism /unmount-image /commit)." -ForegroundColor Yellow
