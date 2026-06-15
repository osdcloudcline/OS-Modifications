Write-Host "The Source Image Location prompt is the CUSTOM Windows image WIM file you are exporting" -ForegroundColor Red
Write-Host
Write-Host "The Destination Image Location prompt is the actual Windows install.wim file you are exporting to CUSTOM image TO!" -ForegroundColor Red
Write-Host


Function Show-CustomExport(){
$WIMSource = Read-Host -Prompt 'Please enter the source image file location'
$WIMDestination = Read-Host -Prompt 'Please enter destination path for extracted WIM File'

$WIMQuestrion = Read-Host -Prompt 'Do you want to add another CUSTOM image to the install.wim file?'
}

Function Show-WIMInfo(){

}

If(($WIMQuestion -eq "YES") -or ($WIMQuestion -eq "yes") -or ($WIMQuestion -eq "Y") -or ($WIMQuestion -eq "y"){
Show-CustomExport
}elseif(($WIMQuestion -eq "NO") -or ($WIMQuestion -eq "no") -or ($WIMQuestion -eq "N") -or ($WIMQuestion -eq "n"){
Show-WIMInfo
}



