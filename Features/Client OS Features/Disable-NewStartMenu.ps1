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
Write-Host 
Write-Host 
Write-Host ' This script will disable the new Start Menu beginning in '
Write-Host ' Windows 11 versions 24H2 going forward and revert it back to the'
Write-Host ' original styled smaller Start Menu                               '
Write-Host
Write-Host
Write-Host
Write-Host ' ' -NoNewline
pause


##########################################################
# Prompt user for path to install media (USB drive) or 
# folder where ISO content was copied to.
#
# Using 'while' loop to check that source given by user 
# contains a Windows image, if not user is asked to check
# path and try again
##########################################################

$WimCount = 0
$ImagePath = ""

while ($WimCount -eq 0) {
    cls
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         WINDOWS INSTALLATION MEDIA PATH CHECK            " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Please enter the drive letter (e.g., D:\) or folder path"
    Write-Host " where your Windows 11 installation files are located:"
    Write-Host ""
    
    $UserPath = Read-Host -Prompt " Path"
    
    # Ensure the path ends with a backslash for formatting consistency
    if ($UserPath -notlike "*\") { $UserPath += "\" }

    # Define common paths for Windows image files (WIM or ESD)
    $WimPath = Join-Path $UserPath "sources\install.wim"
    $EsdPath = Join-Path $UserPath "sources\install.esd"

    # Validate if either file exists
    if (Test-Path $WimPath) {
        $ImagePath = $WimPath
        $WimCount = 1
    } 
    elseif (Test-Path $EsdPath) {
        $ImagePath = $EsdPath
        $WimCount = 1
    } 
    else {
        Write-Host ""
        Write-Warning " Error: Could not find 'install.wim' or 'install.esd' in '$UserPath`sources\'"
        Write-Host " Please verify your path and try again." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

cls
Write-Host " Success! Found Windows Image at: $ImagePath" -ForegroundColor Green
Write-Host ""
##########################################################
# Next Step: Add your deployment image servicing (DISM) 
# or registry modifications below this line.
##########################################################

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
Write-Host ' Please enter the folder for you extracted Windows 11 Install.wim'
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
Write-Host ' Image mounted, modifying image.'
Write-Host



Write-Host "Processing: Index $index" -ForegroundColor Cyan
Write-Host

reg load HKLM\OfflineSoftware "$Mount\Windows\System32\config\SOFTWARE"

reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "EnabledState" /t REG_DWORD /d 1 /f
reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "StateOptions" /t REG_DWORD /d 1 /f

reg unload HKLM\OfflineSoftware

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
# Clean up temporary directories and finish script
##########################################################

Write-Host ""
Write-Host " Removing temporary folder '$Mount'..."
if (Test-Path $Mount) {
    Remove-Item -Path $Mount -Recurse -Force | Out-Null
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "                SCRIPT COMPLETED SUCCESSFULLY             " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host " The Windows 11 image (Index $Index) inside:"
Write-Host " '$WimFile'"
Write-Host " has been updated to disable the new Start Menu structure."
Write-Host ""
Write-Host " Press any key to exit..."

Write-Host ' ' -NoNewline
Pause
