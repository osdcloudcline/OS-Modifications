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
Write-Host ' This script will update Windows 10 install media with new drivers'
Write-Host ' downloaded from http://www.catalog.update.microsoft.com'
Write-Host 
Write-Host ' Please notice that the process will take quite some time, depending'
Write-Host ' on amount and size of drivers being applied to Windows image. '
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
# Delete possible old log files from previous runs
##########################################################

if (Test-Path C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log) {Remove-Item C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log}
if (Test-Path C:\OSDCloud\Logs\OSDrivers\DriverFail.log) {Remove-Item C:\OSDCloud\Logs\OSDrivers\DriverFail.log}

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
# Prompt user for folder containing downloaded WU files
# (*.cab and / or *.msu). Again, a 'while' loop is used to
# check folder contains Windows Update files, if not user
# is asked to check path and try again
##########################################################

$FileCount = 0
while ($FileCount -eq 0) {
cls
Write-Host 
Write-Host '  Enter path to folder containing driver'
Write-Host '  *.inf files.'
Write-Host 
Write-Host '  Be sure to enter correct path / folder!'
Write-Host                                                                       

$DriverFolder = Read-Host -Prompt ' Path to folder containing driver files'

if (Test-Path $DriverFolder)
    {
    $FileCount = (Get-ChildItem $DriverFolder\* -Include *.inf).Count
    if ($FileCount -eq 0)
        {
        Write-Host
        Write-Host ' No driver files found in given folder.' 
        Write-Host ' Check the path and try again.'
        Write-Host
        Write-Host ' ' -NoNewline
        pause
        }
    }
    else
        {
        $FileCount = 0
        cls
        Write-Host
        Write-Host ' Path'$DriverFolder 'does not exist.'
        Write-Host
        Write-Host ' ' -NoNewline
        Pause
        }
  }
$DriverFiles = Get-ChildItem -Path "$DriverFolder" -Recurse -Include *.inf, *.cat, *.sys, *.dll | Sort LastWriteTime 
Write-Host
Write-Host ' Found following' $FileCount 'Drivers files:'
Write-Host
ForEach ($File in $DriverFiles)
    {Write-Host ' '$File}
Write-Host
Write-Host ' ' -NoNewline
pause 

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
Write-Host ' Image mounted, applying drivers.'
Write-Host

##########################################################
# Prompt user for folder containing downloaded WU files
# (*.cab and / or *.msu). Again, a 'while' loop is used to
# check folder contains Windows Update files, if not user
# is asked to check path and try again
##########################################################

$FileCount = 0
while ($FileCount -eq 0) {
cls
Write-Host 
Write-Host '  Enter path to folder containing driver'
Write-Host '  *.inf files.'
Write-Host 
Write-Host '  Be sure to enter correct path / folder!'
Write-Host                                                                       

$DriverFolder1 = Read-Host -Prompt ' Path to folder containing driver files'

if (Test-Path $DriverFolder1)
    {
    $FileCount = (Get-ChildItem $DriverFolder1\* -Include *.inf).Count
    if ($FileCount -eq 0)
        {
        Write-Host
        Write-Host ' No driver files found in given folder.' 
        Write-Host ' Check the path and try again.'
        Write-Host
        Write-Host ' ' -NoNewline
        pause
        }
    }
    else
        {
        $FileCount = 0
        cls
        Write-Host
        Write-Host ' Path'$DriverFolder1 'does not exist.'
        Write-Host
        Write-Host ' ' -NoNewline
        Pause
        }
  }
$DriverFiles = Get-ChildItem -Path "$DriverFolder1" -Recurse -Include *.inf, *.cat, *.sys, *.dll | Sort LastWriteTime 
Write-Host
Write-Host ' Found following' $FileCount 'Drivers files:'
Write-Host
ForEach ($File in $DriverFiles)
    {Write-Host ' '$File}
Write-Host
Write-Host ' ' -NoNewline
pause 

##########################################################
# Write drivers one by one to Windows image. If OK, add
# driver name to 'DriverSuccess.log' file,
# if failed add to 'DriverFail.log'
##########################################################

ForEach ($File in $DriverFiles1)
    {dism /Image:$Mount /Add-Driver /driver:$DriverFolder1 /forceunsigned}  
    Write-Host ' Applying'$File
    {
    if ($? -eq $TRUE)
        {$File.Name | Out-File -FilePath C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log -Append}
     else     
        {$File.Name | Out-File -FilePath C:\OSDCloud\Logs\OSDrivers\DriverFail.log -Append}
        break
    }
    
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

##########################################################
# Show drivers added to Windows image
##########################################################

if (Test-Path C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log)
    {
    Write-Host
    Write-Host ' Following drivers successfully added to Windows image: '
    Write-Host
    $LogContent = Get-Content 'C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log'
    foreach ($Line in $LogContent)
        {Write-Host ' - '$Line}
    } 
    else
    {
    Write-Host
    Write-Host ' All drivers failed, nothing added to Windows image.'
    Write-Host
    Write-Host ' ' -NoNewline
    pause
    exit
    }

##########################################################
# Show failed drivers
##########################################################

if (Test-Path C:\OSDCloud\Logs\OSDrivers\DriverFail.log)
    {
    Write-Host
    Write-Host ' Following drivers could not be added to Windows image: '
    $LogContent = Get-Content 'C:\OSDCloud\Logs\OSDrivers\DriverFail.log'
    foreach ($Line in $LogContent)
        {Write-Host ' - '$Line}
    } 
    else
    {
    Write-Host
    Write-Host ' No failed drivers.'}

##########################################################
# Delete temporary mount folder
##########################################################

if (Test-Path $Mount) {Remove-Item $Mount}

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

$ISOFolder1 = Read-Host -Prompt ' Enter source, press Enter'
$WimFolder1 = $ISOFolder1
   
    if (Test-Path $WimFolder1\Sources\boot.wim)
        {
        $WimCount = 1
            if (($WIMFolder1 -match "x86") -or ($WIMFolder1 -match "x64"))
            {
            $ISOFolder1 = $ISOFolder1 -replace "....$" 
            }
        }
    elseif (Test-Path $WimFolder1)
        {
        $WimCount = 0
        cls
        Write-Host
        Write-Host ' No Windows image (boot.wim file) found'
        Write-Host ' Please check path and try again.'
        Write-Host
        Pause
        }
    else
        {
        $FileCount = 0
        cls
        Write-Host
        Write-Host ' Path'$ISOFolder1 'does not exist.'
        Write-Host
        Write-Host ' ' -NoNewline
        Pause
        }
    }

$WimFile1 = Join-Path $WimFolder1 '\Sources\boot.wim'

##########################################################
# Prompt user for folder containing downloaded WU files
# (*.cab and / or *.msu). Again, a 'while' loop is used to
# check folder contains Windows Update files, if not user
# is asked to check path and try again
##########################################################

$FileCount = 0
while ($FileCount -eq 0) {
cls
Write-Host 
Write-Host '  Enter path to folder containing driver'
Write-Host '  *.inf files.'
Write-Host 
Write-Host '  Be sure to enter correct path / folder!'
Write-Host                                                                       

$DriverFolder2 = Read-Host -Prompt ' Path to folder containing boot driver files'

if (Test-Path $DriverFolder2)
    {
    $FileCount = (Get-ChildItem $DriverFolder2\* -Include *.inf).Count
    if ($FileCount -eq 0)
        {
        Write-Host
        Write-Host ' No driver files found in given folder.' 
        Write-Host ' Check the path and try again.'
        Write-Host
        Write-Host ' ' -NoNewline
        pause
        }
    }
    else
        {
        $FileCount = 0
        cls
        Write-Host
        Write-Host ' Path'$DriverFolder2 'does not exist.'
        Write-Host
        Write-Host ' ' -NoNewline
        Pause
        }
  }

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
$Mount = $Drive.SubString(0,1) + ':\BootWIMMount'

if (Test-Path $Mount1) {Remove-Item $Mount1}
$Mount1 = New-Item -ItemType Directory -Path $Mount1

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
Mount-WindowsImage -ImagePath $WimFolder\Sources\boot.wim -Index $Index -Path $Mount1 | Out-Null
Write-Host
Write-Host ' Image mounted, applying drivers.'
Write-Host

##########################################################
# Write drivers one by one to Windows image. If OK, add
# driver name to 'DriverSuccess.log' file,
# if failed add to 'DriverFail.log'
##########################################################

ForEach ($File in $DriverFiles2)
    {dism /Image:$Mount1 /Add-Driver /Driver:$DriverFolder2 /Recurse /ForceUnsigned} 
    Write-Host ' Applying'$File
    {
    if ($? -eq $TRUE)
        {$File.Name | Out-File -FilePath C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log -Append}
     else     
        {$File.Name | Out-File -FilePath C:\OSDCloud\Logs\OSDrivers\DriverFail.log -Append}
    }

##########################################################
# Dismount Windows image saving updated boot.wim. Using
# $EmptySpace variable again to push output from under
# PowerShell progressbar to visible area under it
##########################################################

cls
Write-Host $EmptySpace
Write-Host ' Dismounting Windows image, saving updated boot.wim.'
Write-Host ' This will take a minute or two.'
Dismount-WindowsImage -Path $Mount -Save | Out-Null
cls

##########################################################
# Show drivers added to Windows image
##########################################################

if (Test-Path C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log)
    {
    Write-Host
    Write-Host ' Following drivers successfully added to Windows image: '
    Write-Host
    $LogContent = Get-Content 'C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log'
    foreach ($Line in $LogContent)
        {Write-Host ' - '$Line}
    } 
    else
    {
    Write-Host
    Write-Host ' All drivers failed, nothing added to Windows image.'
    Write-Host
    Write-Host ' ' -NoNewline
    pause
    exit
    }

##########################################################
# Show failed drivers
##########################################################

if (Test-Path C:\OSDCloud\Logs\OSDrivers\DriverFail.log)
    {
    Write-Host
    Write-Host ' Following drivers could not be added to Windows image: '
    $LogContent = Get-Content 'C:\OSDCloud\Logs\OSDrivers\DriverFail.log'
    foreach ($Line in $LogContent)
        {Write-Host ' - '$Line}
    } 
    else
    {
    Write-Host
    Write-Host ' No failed drivers.'}

##########################################################
# Delete temporary mount folder
##########################################################

if (Test-Path $Mount1) {Remove-Item $Mount1}

##########################################################
# End credits
##########################################################

Write-Host                                                                        
Write-Host ' Windows image (install.wim and boot.wim) has been updated.'
Write-Host 
Write-Host ' If your source was a bootable USB drive, it is now updated.'
Write-Host  
Write-Host ' If you started this script by copying Windows install files'
Write-Host ' from an ISO or DVD to a folder on hard disk, it now contains.'
Write-Host ' everything required to create updated ISO image.'
Write-Host 
Write-Host ' Creating ISO tutorial on TenForums:'
Write-Host ' w10g.eu/iso' -ForegroundColor Yellow
Write-Host   
Write-Host ' More Windows 10 tips, tricks, videos & tutorials at'
Write-Host ' TenForums.com' -ForegroundColor Yellow
Write-Host
Write-Host ' * Twitter.com/TenForums * Facebook.com/TenForums * ' -ForegroundColor Yellow
Write-Host 
Write-Host ' Script by Kari'
Write-Host ' - TenForums.com/members/kari.html'
Write-Host ' - Twitter.com/KariTheFinn'
Write-Host ' - YouTube.com/KariTheFinn'
Write-Host  
Write-Host ' Logs were saved on C: drive. They can be opened with Notepad:'
Write-Host ' - C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log > lists applied drivers'
Write-Host ' - C:\OSDCloud\Logs\OSDrivers\DriverFail.log > lists failed drivers'
Write-Host


##########################################################
# End of script
##########################################################
