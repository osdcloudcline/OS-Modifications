$source = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"
$destination = "C:\downloads"
$extract = "C:\downloads\extract\OS\Win11-FoD\25H2"
$OSISOextract = "C:\OS\Windows11"

Save-WebFile -SourceUrl $source -DestinationDirectory $destination

$isoPath = "C:\downloads\26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"



$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter
New-Item -Path $extract -ItemType Directory -Forc
Copy-Item -Path "${driveLetter}:\*" -Destination $extract -Recurse -Force

$ospath = "Read-Host -Prompt 'Please enter your path where your extracted OS is'
$mount = Read-Host -Prompt 'Please enter your path to use as a Mount point'

$OSIso = Read-Host -Prompt 'Please enter path to your Windows 11 ISO File'
$mountResult1 = Mount-DiskImage -ImagePath $OSIso -PassThru
$driveLetter1 = ($mountResult1 | Get-Volume).DriveLetter
New-Item -Path $OSISOextract -ItemType Directory -Force
Copy-Item -Path "${driveLetter}:\*" -Destination $OSISOextract -Recurse -Force

$Index3 = "Windows 11 Professional 25H2"

Write-Host "Processing: $Index3" -ForegroundColor Cyan
Mount-WindowsImage -ImagePath $ospath -Index 3 -Path $mount
Write-Host
Write-Host "Processing: Windows RSAT Tools" -ForegroundColor Cyan
Get-WindowsCapability -Path $mount -Name RSAT*| Add-WindowsCapability -Path $mount -LimitAccess -Source $extract
Write-Host
Write-Host "Saving changes to $Index3" -ForegroundColor Cyan
Dismount-WindowsImage -Path $mount -Save

$Index6 = "Windows 11 Enterprise 25H2"

Write-Host "Processing: $Index6" -ForegroundColor Cyan
Mount-WindowsImage -ImagePath $ospath -Index 6 -Path $mount
Write-Host
Write-Host "Processing: Windows RSAT Tools" -ForegroundColor Cyan
Get-WindowsCapability -Path $mount -Name RSAT*| Add-WindowsCapability -Path $mount -LimitAccess -Source $extract
Write-Host
Write-Host "Saving changes to $Index6" -ForegroundColor Cyan
Dismount-WindowsImage -Path $mount -Save

$Index12 = "Windows 11 Pro for Workstations 25H2"

Write-Host "Processing: $Index12" -ForegroundColor Cyan
Mount-WindowsImage -ImagePath $ospath -Index 12 -Path $mount
Write-Host
Write-Host "Processing: Windows RSAT Tools" -ForegroundColor Cyan
Get-WindowsCapability -Path $mount -Name RSAT*| Add-WindowsCapability -Path $mount -LimitAccess -Source $extract
Write-Host
Write-Host "Saving changes to $Index12" -ForegroundColor Cyan
Dismount-WindowsImage -Path $mount -Save
