$source = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"
$destination = "C:\downloads"
$extract = "C:\downloads\extract\OS\Win11-FoD\25H2"
$OSISOextract = "C:\OS\Windows11"

Save-WebFile -SourceUrl $source -DestinationDirectory $destination

$isoPath = "C:\downloads\26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"



$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter
New-Item -Path $extract -ItemType Directory -Force
Copy-Item -Path "${driveLetter}:\*" -Destination $extract -Recurse -Force

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
Write-Host ' This script will add all RSAT Administration Tools to the  '
Write-Host ' selected Windows 11 version                                '                           '
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

Write-Host "Adding RSAT Tools to the offline mounted WIM file" -ForegroundColor Cyan 
Get-WindowsCapability -Path $mount -Name RSAT*| Add-WindowsCapability -Path $mount -LimitAccess -Source $extract
Write-Host
Write-Host "Saving changes" -ForegroundColor Cyan
Dismount-WindowsImage -Path $Mount -Save


