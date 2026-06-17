########################################################## 
# 
# USBUpdate.ps1
#
# A PS Script to update Windows 10 install USB. 
# 
# You are free to edit & share this script as long as
# source TenForums.com is mentioned.
#
# *** Twitter.com/TenForums *** Facebook.com/TenForums ***
# 
# Script by Kari 
# - TenForums.com/members/kari.html
# - Twitter.com/KariTheFinn
# - YouTube.com/KariTheFinn
#
# 'Use-RunAs' function to check if script was launched
# in normal user mode and elevating it if necessary by
# Matt Painter (Microsoft TechNet Script Center)
# https://gallery.technet.microsoft.com/scriptcenter/ 
#
##########################################################

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
Write-Host ' This script will integrate registry files with Windows install media '
Write-Host ' downloaded from OSDCloud Cline repo'
Write-Host 
Write-Host ' Please notice that the process will take quite some time, depending'
Write-Host ' on amount and size of registry entry being applied to Windows image. '
Write-Host
Write-Host ' If you already have a bootable Windows 10 install media on USB '
Write-Host ' flash drive, plug it in now.'
Write-Host 
Write-Host ' If you want to upgrade an ISO instead, mount (double click) a Windows'
Write-Host ' ISO image and copy its content to a folder on local PC, for instance'
Write-Host ' "D:\ISO_Files". Make sure the folder has no other content.'
Write-Host 
Write-Host ' When ISO files have been copied to a hard disk folder, or USB drive'
Write-Host ' has been plugged in, press Enter to start.'
Write-Host 
Write-Host '                                                                      ' -ForegroundColor DarkBlue -BackgroundColor White
Write-Host ' Notice that you cannot use this script to update an ESD based install' -ForegroundColor DarkBlue -BackgroundColor White
Write-Host ' media like for instance ISO / USB made with Media Creation Tool.     ' -ForegroundColor DarkBlue -BackgroundColor White
Write-Host ' You must first convert "install.esd" file to "install.wim". See      ' -ForegroundColor DarkBlue -BackgroundColor White
Write-Host ' TenForums tutorial "Convert ESD to WIM":' -ForegroundColor DarkBlue -BackgroundColor White -NoNewline
Write-Host ' http://w10g.eu/esd2wim      ' -ForegroundColor DarkCyan -BackgroundColor White
Write-Host '                                                                      ' -ForegroundColor DarkBlue -BackgroundColor White
Write-Host
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

##########################################################
# Ask user which drive should be used for temporary 
# working folder 'Mount'. If 'Mount' exists on selected
# drive, delete and recreate it.
##########################################################

cls
Write-Host
[System.IO.DriveInfo]::GetDrives() | Where-Object {$_.DriveType -eq 'Fixed'} | Format-Table @{n='Drive ID';e={($_.Name)}}, @{n='Label';e={($_.VolumeLabel)}}, @{n='Free (GB)';e={[int]($_.AvailableFreeSpace/1GB)}}
Write-Host
Write-Host ' Above is a list of all hard disk partitions showing available'
Write-Host ' free space on each of them. Select a partition for temporary'
Write-Host ' folder to mount Windows image. Selected partition must have at'
Write-Host ' least 15 GB available free space. Folder will be removed when'
Write-Host ' image has been updated.'
Write-Host
$Drive = Read-Host -Prompt ' Enter drive letter and press Enter'
$Mount = $Drive.SubString(0,1) + ':\Mount'

if (Test-Path $Mount) {Remove-Item $Mount}
$Mount = New-Item -ItemType Directory -Path $Mount

##########################################################
# Mount Windows image in temporary mount folder.
#
# Adding eight empty lines to $EmptySpace variable to be
# used as placeholder to push output below PowerShell
# progressbar which is shown on top. Five empty lines would
# be enough for PowerShell ISE but standard PowerShell will
# need eight lines, otherwise output remains hidden
##########################################################

cls
$EmptySpace = @"



  
 



"@

Write-Host $EmptySpace
Write-Host ' Mounting Windows image. This will take a few minutes.'
Mount-WindowsImage -ImagePath $WimFolder\Sources\install.wim -Index $Index -Path $Mount | Out-Null
Write-Host
Write-Host ' Image mounted.'
Write-Host

##########################################################
# Write registry entries one by one to Windows image.

##########################################################

$HKCRREG1 = "Add Copy To Move To"

reg load HKLM\OfflineSystem "$Mount\Windows\System32\config\SYSTEM"

Write-Host "Importing $HKCRREG1...." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKCRREG1..." -Verbose
reg add "HKLM\OfflineSystem\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /f

reg unload HKLM\OfflineSystem

reg load HKLM\OfflineSoftware "$Mount\Windows\System32\config\SOFTWARE"

$HKCRREG2 = "Add Safe Mode"



Write-Host "Importing $HKCRREG2..." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKCRREG2..." -Verbose


reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode" /v "icon" /t REG_SZ /d "bootux.dll,-1032" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode" /v "MUIVerb" /t REG_SZ /d "Safe Mode" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode" /v "Position" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode" /v "SubCommands" /t REG_SZ /d "" /f


reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\001-NormalMode" /ve /t REG_SZ /d "Restart in Normal Mode" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\001-NormalMode" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\001-NormalMode\command" /ve /t REG_SZ /d "powershell -windowstyle hidden -command \"Start-Process cmd -ArgumentList '/s,/c,bcdedit /deletevalue {default} safeboot & bcdedit /deletevalue {default} safebootalternateshell & shutdown -r -t 00 -f' -Verb runAs\"" /f


reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\002-SafeMode" /ve /t REG_SZ /d "Restart in Safe Mode" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\002-SafeMode" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\002-SafeMode\command" /ve /t REG_SZ /d "powershell -windowstyle hidden -command \"Start-Process cmd -ArgumentList '/s,/c,bcdedit /set {default} safeboot minimal & bcdedit /deletevalue {default} safebootalternateshell & shutdown -r -t 00 -f' -Verb runAs\"" /f


reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\003-SafeModeNetworking" /ve /t REG_SZ /d "Restart in Safe Mode with Networking" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\003-SafeModeNetworking" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\003-SafeModeNetworking\command" /ve /t REG_SZ /d "powershell -windowstyle hidden -command \"Start-Process cmd -ArgumentList '/s,/c,bcdedit /set {default} safeboot network & bcdedit /deletevalue {default} safebootalternateshell & shutdown -r -t 00 -f' -Verb runAs\"" /f


reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\004-SafeModeCommandPrompt" /ve /t REG_SZ /d "Restart in Safe Mode with Command Prompt" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\004-SafeModeCommandPrompt" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\OfflineSoftware\Classes\DesktopBackground\Shell\SafeMode\shell\004-SafeModeCommandPrompt\command" /ve /t REG_SZ /d "powershell -windowstyle hidden -command \"Start-Process cmd -ArgumentList '/s,/c,bcdedit /set {default} safeboot minimal & bcdedit /set {default} safebootalternateshell yes & shutdown -r -t 00 -f' -Verb runAs\"" /f

reg unload HKLM\OfflineSoftware

$HKLMREG1 = "Adobe Master Collection Suite"

Write-Host "Importing $HKLMREG1..." -ForegroundColor Cyan
Write-Host 
Write-Verbose "Adding $HKLMREG1..." -Verbose

reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cCloud" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultExecMenuItems" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultFindAttachmentPerms" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchAttachmentPerms" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cSharePoint" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cWebmailProfiles" /f

reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cCloud" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cIPM" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cSharePoint" /f
reg add "HKLM\OfflineSoftware\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cWebmailProfiles" /f

reg add "HKLM\OfflineSoftware\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cCloud" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cIPM" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cSharePoint" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cWebmailProfiles" /f

reg add "HKLM\OfflineSoftware\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultExecMenuItems" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultFindAttachmentPerms" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchAttachmentPerms" /f
reg add "HKLM\OfflineSoftware\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f

pause 

$HKLMREG2 = "Google Chrome AI"

Write-Host "Importing $HKLMREG2..." -ForegroundColor Cyan
Write-Host 
Write-Verbose "Adding $HKLMREG2..." -Verbose


reg add "HKLM\OfflineSoftware\Policies\Google\Chrome" /v "GenAILocalFoundationalModelSettings" /t REG_DWORD /d 1 /f
reg add "HKLM\OfflineSoftware\Policies\Google\Chrome" /v "GenAiDefaultSettings" /t REG_DWORD /d 2 /f
reg add "HKLM\OfflineSoftware\Policies\Google\Chrome" /v "AIModeSettings" /t REG_DWORD /d 1 /f

reg unload HKLM\OfflineSoftware

pause

reg load HKLM\OfflineSystem $Mount\Windows\System32\Config\SYSTEM

$HKSYSTEMREG1 = "Disable BitLocker Device Encryption"


Write-Host "Importing $HKSYSTEMREG1...." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKSYSTEMREG1..." -Verbose
reg add "HKLM\OfflineSystem\ControlSet001\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f

reg unload HKLM\OfflineSystem



$HKLMSYSTEMREG2 = "Disable Windows Defender"

reg load HKLM\OfflineSystem $Mount\Windows\System32\Config\SYSTEM
reg load HKLM\OfflineSoftware "$Mount\Windows\System32\config\SOFTWARE"

Write-Host "Importing $HKLMSYSTEMREG2..." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKLMSYSTEMREG2..." -Verbose

reg add "HKLM\OfflineSoftware\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f
reg add "HKLM\OfflineSettings\CurrentControlSet\Services\Sense" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OfflineSystem\CurrentControlSet\Services\WdFilter" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OfflineSystem\CurrentControlSet\Services\WdBoot" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OfflineSoftware\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f 

reg add "HKLM\OfflineSystem\ControlSet001\Services\WinDefend" /v Start /t REG_DWORD /d 4 /f

reg unload HKLM\OfflineSystem
reg unload HKLM\OfflineSoftware

pause

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
