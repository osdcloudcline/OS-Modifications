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

Function Show-IntelDrivers(){

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


Write-Host "WARNING: Please select source folders of your drivers, rather putting them in a flat directory or problems may occur!" - ForegroundColor Red 
Write-Host
Write-Host 

# Define the categories and whether they accept multiple folders
$DriverSchema = @(
    @{ Name = "Audio";       Multi = $false; Prompt = "audio drivers" }
    @{ Name = "Chipset";    Multi = $true;  Prompt = "chipset drivers" }
    @{ Name = "Graphics";   Multi = $true;  Prompt = "graphics card drivers" }
    @{ Name = "Monitor";    Multi = $true;  Prompt = "monitor drivers" }
    @{ Name = "Network";    Multi = $true;  Prompt = "network card drivers" }
    @{ Name = "NPU";        Multi = $false; Prompt = "NPU drivers" }
    @{ Name = "Printer";    Multi = $true; Prompt = "printer drivers" }
    @{ Name = "Storage";    Multi = $false; Prompt = "storage drivers" }
    @{ Name = "CPU";        Multi = $true;  Prompt = "CPU drivers" }
    @{ Name = "Virtualization";      Multi = $true;  Prompt = "Virtualization drivers" }
)

# Initialize an empty array list to gather paths dynamically
$AllIntelDrivers = [System.Collections.Generic.List[string]]::new()

Write-Host "--- OSDCloud Driver Path Collection ---" -ForegroundColor Yellow
Write-Host "Press [Enter] without typing a path to skip or finish a category.`n" -ForegroundColor Gray

# Loop through each driver category dynamically
foreach ($Category in $DriverSchema) {
    if ($Category.Multi) {
        $Index = 1
        while ($true) {
            $InputPath = (Read-Host -Prompt "Please provide folder where $($Category.Prompt) ($Index) are stored").Trim()
            
            # Break loop if user hits Enter on a blank line
            if ([string]::IsNullOrWhiteSpace($InputPath)) { break }
            
            $AllIntelDrivers.Add($InputPath)
            $Index++
        }
    } else {
        $InputPath = (Read-Host -Prompt "Please provide folder where $($Category.Prompt) are stored").Trim()
        if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
            $AllIntelDrivers.Add($InputPath)
        }
    }
}


##########################################################
# Write drivers one by one to Windows image. If OK, add
# driver name to 'DriverSuccess.log' file,
# if failed add to 'DriverFail.log'
##########################################################



foreach ($File in $AllIntelDrivers) {
    # Visual anchor for tracking progress
    Write-Host "Applying drivers from: $File" -ForegroundColor Cyan

    # FIX 1: Pass "$File" instead of the whole array.
    # FIX 2: Wrap "$Mount" and "$File" in double quotes to handle folder spaces safely.
    dism.exe /Image:"$Mount" /Add-Driver /driver:"$File" /Recurse /ForceUnsigned

    # FIX 3: Check execution status immediately after the command runs
    if ($LASTEXITCODE -eq 0) {
        # FIX 4: $File is a plain string path, so use Split-Path to extract just the folder name
        $FolderName = Split-Path $File -Leaf
        $FolderName | Out-File -FilePath "C:\OSDCloud\Logs\OSDrivers\DriverSuccess.log" -Append
    } else {
        $FolderName = Split-Path $File -Leaf
        $FolderName | Out-File -FilePath "C:\OSDCloud\Logs\OSDrivers\DriverFail.log" -Append
    }
    
    # FIX 5: Removed 'break' so the script continues to the next driver folder!
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

$Main = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/OSModsMainMenu.ps1")
Invoke-Expression $($Main.Content)

# End of script
##########################################################

}


Function Show-AMDDrivers(){

##########################################################
# Show short instructions to user
##########################################################   

cls
Write-Host                                                                       
Write-Host ' This script will update Windows 10 install media with new drivers'
Write-Host ' for AMD CPU systems'
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
Write-Host ' Image mounted, applying drivers.'
Write-Host

$AudioDrivers   = Read-Host -Prompt 'Please provide folder where audio drivers are stored'
$ChipsetDrivers = Read-Host -Prompt 'Please provide folder where chipset drivers are stored'
$GPUDrivers     = Read-Host -Prompt 'Please provide folder where graphics card drivers are stored'
$MonitorDrivers = Read-Host -Prompt 'Please provide folder where monitor drivers are stored'
$NetworkDrivers = Read-Host -Prompt 'Please provide folder where network card drivers are stored' 
$NPUDrivers     = Read-Host -Prompt 'Please provide folder where NPU drivers are stored' 
$PrinterDrivers = Read-Host -Prompt 'Please provide folder where printer drivers are stored' 
$StorageDrivers = Read-Host -Prompt 'Please provide folder where storage drivers are stored' 
$CPUDrivers       = Read-Host -Prompt 'Please provide folder where CPU drivers are stored'

# Combines all separate paths into one array variable
$AllAMDDrivers = @(
    $AudioDrivers
    $ChipsetDrivers
    $GPUDrivers
    $MonitorDrivers
    $NetworkDrivers
    $NPUDrivers
    $PrinterDrivers
    $StorageDrivers
    $CPUDrivers
)

##########################################################
# Write drivers one by one to Windows image. If OK, add
# driver name to 'DriverSuccess.log' file,
# if failed add to 'DriverFail.log'
##########################################################



ForEach ($File in $DriverFiles)
    {dism /Image:$Mount /Add-Driver /driver:$AllAMDDrivers /forceunsigned}  
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

$Main = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/OSModsMainMenu.ps1")
Invoke-Expression $($Main.Content)

# End of script
##########################################################

}


$Ques = Read-Host -Prompt 'Do you have an Intel or AMD CPU?'
If($Ques -eq "Intel"){
Use-RunAs
Show-IntelDrivers
}
elseif($Ques -eq "AMD"){
Use-RunAs    
Show-AMDDrivers
}









