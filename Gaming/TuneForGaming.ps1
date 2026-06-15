<#
.SYNOPSIS
    Streamlines Windows 11 Enterprise into a high-performance Pro gaming environment.
.DESCRIPTION
    Removes enterprise-specific background infrastructure, stops heavy kernel logging, 
    disables performance-hogging security virtualization, and applies Pro-tier gaming tweaks.
#>

# 1. Create Safe Fallback Target
Write-Host "[*] Creating a System Restore Point..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "EnterpriseToProGaming" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

# 2. Disable Enterprise-Specific Background Services & Features
Write-Host "[*] Disabling Enterprise infrastructure & auditing..." -ForegroundColor Cyan

# Disable Diagnostic Policy & Enterprise Distributed Link Tracking (heavy background disk I/O)
Stop-Service -Name "DPS", "TrkWks" -Force -ErrorAction SilentlyContinue
Set-Service -Name "DPS", "TrkWks" -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Windows Defender Application Control (WDAC) Smart App Control evaluation overhead
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 0

# Disable Enterprise Feedback, Telemetry, and Cloud Experience (NCSI probing)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 0 # Re-enables standard retail Pro behavior

# 3. Disable Virtualization-Based Security (VBS) & Core Isolation
# NOTE: VBS is highly active on Enterprise and can cause a 5-15% drop in gaming frame rates.
Write-Host "[*] Turning off Virtualization-Based Security (VBS) to unlock CPU overhead..." -ForegroundColor Cyan
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "RequirePlatformSecurityFeatures" -Value 0

# Disable Hypervisor-Enforced Code Integrity (HVCI / Core Isolation Memory Integrity)
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0

# 4. Standard Pro-Gaming Optimizations (Game Mode & GPU Scheduling)
Write-Host "[*] Enabling Windows 11 Gaming Features..." -ForegroundColor Cyan

# Force Windows Game Mode Active
New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1

# Activate Hardware-Accelerated GPU Scheduling (HAGS)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2

# Enable Optimizations for Windowed/Borderless Games
New-Item -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalFlags" -Value 2

# Disable background GameDVR (Stops stuttering from continuous background recording)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "HistoricalCaptureEnabled" -Value 0

# 5. Activate Pro-Tier Performance Power Management
Write-Host "[*] Deploying High Performance power policies..." -ForegroundColor Cyan
# Unlock and activate the Ultimate Performance overlay scheme
$UltimateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"
powercfg -duplicatescheme $UltimateGUID | Out-Null
powercfg -setactive $UltimateGUID

# Disable CPU Core Parking under the active plan
powercfg -setacvalueindex scheme_current sub_processor cppa 0
powercfg -setactive scheme_current

# 6. Low-Latency Network Tuning
Write-Host "[*] Tuning network stack for retail Pro low-latency gaming..." -ForegroundColor Cyan
# Disable system network throttling index
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0

# Disable Nagle's Algorithm to bypass packet queuing delays
$InterfacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem -Path $InterfacesPath | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
}

Write-Host "`n[✓] Script executed successfully! Your Windows 11 Enterprise installation has been streamlined for gaming." -ForegroundColor Green
Write-Host "[!] A system restart is REQUIRED to safely disable VBS/HVCI and update network hooks." -ForegroundColor Yellow
