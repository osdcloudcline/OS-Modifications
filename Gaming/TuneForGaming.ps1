##########################################################
# Checking if PS is running elevated. If not, elevating it
##########################################################   

function Use-RunAs 
{    
    # Check if script is running as Administrator and if not elevate it
    # Use Check Switch to check if admin 
     
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }   
      
    if ($MyInvocation.ScriptName -ne "") 
    {  
        if (-not $IsAdmin)  
          {  
            try 
            {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch 
            { 
                Write-Warning "Error - Failed to restart script elevated"  
                break               
            } 
            exit 
        }  
    }  
} 

Use-RunAs 

##########################################################
# Show short instructions to user
##########################################################   

cls
Write-Host  
Write-Host ' This script will tune Windows 11 ENTERPRISE Edition ONLY '
Write-Host ' for gaming. If you are not planning on installing or are running'
Write-Host ' Windows 11 Enterprise, please exit this script'                                                  '
Write-Host ' ' -NoNewline
pause

##########################################################
# Prompt user for path to install media (USB drive) or 
# folder where ISO content was copied to.
#
# Using 'while' loop to check that source given by user 
# contains a Windows image, if not user is asked to chek
# path and try again
##########################################################

$WimCount = 0
while ($WimCount -eq 0) {
cls
Write-Host 
Write-Host ' Enter source path. In case you are using a plugged in USB flash'
Write-Host ' drive, simply enter its drive letter followed by : (colon).'
Write-Host
Write-Host ' If the source you are using is a Windows 10 ISO or DVD, enter.'
Write-Host ' path to folder where you copied ISO / DVD content.'
Write-Host 
Write-Host ' Notice please: If your source contains both 32 (x86) and 64 (x64)'
Write-Host ' bit versions, add \x86 or \x64 to source depending on which'
Write-Host ' bit version you want to update.'
Write-Host 
Write-Host ' Examples:'
Write-Host ' - A USB drive, enter its drive letter with colon (D: or F:)'
Write-Host ' - A USB drive with both bit versions, enter D:\x86 or D:\x64'
Write-Host ' - ISO files copied to folder, enter path (D:\ISO_Files)'
Write-Host ' - Dual bit version ISO copied to folder, enter path with bit version'
Write-Host '   (W:\MyISOFolder\x86 or W:\MyISOFolder\x64)' 
Write-Host

$ISOFolder = Read-Host -Prompt ' Enter source, press Enter'
$WimFolder = $ISOFolder
   
    if (Test-Path $WimFolder\Sources\install.wim)
        {
        $WimCount = 1
            if (($WIMFolder -match "x86") -or ($WIMFolder -match "x64"))
            {
            $ISOFolder = $ISOFolder -replace "....$" 
            }
        }
    elseif (Test-Path $WimFolder)
        {
        $WimCount = 0
        cls
        Write-Host
        Write-Host ' No Windows image (install.wim file) found'
        Write-Host ' Please check path and try again.'
        Write-Host
        Pause
        }
    else
        {
        $FileCount = 0
        cls
        Write-Host
        Write-Host ' Path'$ISOFolder 'does not exist.'
        Write-Host
        Write-Host ' ' -NoNewline
        Pause
        }
    }

$WimFile = Join-Path $WimFolder '\Sources\install.wim'

##########################################################
# List Windows editions on image, prompt user for
# edition to be updated
##########################################################

cls
Get-WindowsImage -ImagePath $WimFile | Format-Table ImageIndex, ImageName
Write-Host 
Write-Host ' The install.wim file contains above listed Windows editions.'
Write-Host ' Which edition should be updated?'
Write-Host  
Write-Host ' Enter the ImageIndex number of correct edition and press Enter.'
Write-Host ' If this is a single edition Windows image, enter 1.'                                                                     
Write-Host
$Index = Read-Host -Prompt ' Select edition'



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

##########################################################
# Dismount Windows image saving updated install.wim. Using
# $EmptySpace variable again to push output from under
# PowerShell progressbar to visible area under it
##########################################################

cls
Write-Host $EmptySpace
Write-Host ' Dismounting Windows image, saving updated install.wim.'
Write-Host ' This will take a minute or two.'
Dismount-WindowsImage -Path $Mount -Save | Out-Null
cls
