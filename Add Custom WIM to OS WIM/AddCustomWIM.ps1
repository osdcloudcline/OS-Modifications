# -----------------------------
# VARIABLES
# -----------------------------
$CustomWimPath     = $WIMSource
$DestinationWim    = $WIMDestination
$CompressionType   = "max"                            # Options: max, fast, or none




Write-Host "The Source Image Location prompt is the CUSTOM Windows image WIM file you are exporting" -ForegroundColor Cyan 
Write-Host
Write-Host "The Destination Image Location prompt is the actual Windows install.wim file you are exporting to CUSTOM image TO!" -ForegroundColor Cyan
Write-Host



Function Show-CustomExport(){
    
    $WIMSource = (Read-Host -Prompt 'Please enter the source image file location'
    $WIMDestination = (Read-Host -Prompt 'Please enter destination path for extracted WIM File'

    # Validate that the source file actually exists
    if (-not (Test-Path -Path $WIMSource)) {
        Write-Host "Error: Source file does not exist at $WIMSource" -ForegroundColor Red
        return
    }

    Write-Host "Adding custom image to WIM..." -ForegroundColor Cyan
    $Name = Read-Host -Prompt 'Please provide a name for the image'
    Add-WindowsImage -ImagePath $WIMDestination -CapturePath $WIMSource  -Name "$Name"

    $WIMQuestion = Read-Host -Prompt 'Do you want to add another CUSTOM image to the install.wim file?'
    if ($WIMQuestion -in 'YES', 'yes', 'Y', 'y'){
        Show-CustomExport
    } elseif ($WIMQuestion -in 'NO', 'no', 'N', 'n'){
        Show-WIMInfo
    }
}

Function Show-WIMInfo(){
    $WIMInfo = (Read-Host -Prompt 'Please enter the location for the Windows install.wim file'
    if (Test-Path -Path $WIMInfo) {
        Get-WindowsImage -ImagePath $WIMInfo
    } else {
        Write-Host "File not found." -ForegroundColor Red
    }
}

Show-CustomExport





