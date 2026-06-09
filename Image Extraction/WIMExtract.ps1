Function Show-WIMExtract(){

$ISOFolder = Read-Host -Prompt 'Please enter the source directory'
$WimFolder = $ISOFolder
$Destination = Read-Host -Prompt 'Please enter destination path for extracted WIM File'


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
$WimFile = Join-Path $WimFolder '\Sources\install.wim'

##########################################################
# List Windows editions on image, prompt user for
# edition to be updated
##########################################################

cls
Get-WindowsImage -ImagePath $WimFile | Format-Table ImageIndex, ImageName
Write-Host 
Write-Host ' The install.wim file contains above listed Windows editions.'
Write-Host ' Which edition should be extracted?'
Write-Host  
Write-Host ' Enter the ImageIndex number of correct edition and press Enter.'
Write-Host ' If this is a single edition Windows image, enter 1.'                                                                     
Write-Host
$Index = Read-Host -Prompt ' Select edition'

$ExportWIMFileName = Read-Host -Prompt 'Please specify a file name for the exported WIM file, including the file extension (EG: Windows11ProWorkstations.wim)'
$DestinationName = Read-Host -Prompt 'Please enter a descriptive name for the image'

Write-Host "Processing: Exporting selected WIM File" -ForegroundColor Cyan
Write-Host
Export-WindowsImage -SourceImagePath "$WIMFile" -SourceIndex $Index -DestinationImagePath "$Destination\$ExportWIMFileName" -DestinationName "$DestinationName" 
Write-Host
Write-Host "WIM File successfully extracted to: $Destination" -ForegroundColor Green 
}

$OSExtract = Read-Host -Prompt 'Do you want to extract another OS Image?'
If(($OSExtract -eq "Y") -or ($OSExtract -eq "y") -or ($OSExtract -eq "YES") -or ($OSExtract -eq "yes")){
Show-WIMExtract
}elseif(($OSExtract -eq "N") -or ($OSExtract -eq "n") -or ($OSExtract -eq "NO") -or ($OSExtract -eq "no")){
Write-Host "Extraction process has completed" -ForegroundColor Cyan

Show-WIMExtract
