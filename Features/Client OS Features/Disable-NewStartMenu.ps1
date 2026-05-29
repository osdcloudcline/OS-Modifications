$Vivetool = "https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip"
$destination = "C:\downloads\Vivetool"
$ZIP = "C:\downloads\Vivetool\ViVeTool-v0.3.4-IntelAmd.zip"
$extract = "C:\downloads\Vivetool\extract"

Save-WebFile -SourceUrl $Vivetool -DestinationDirectory $destination

Expand-Archive -Path $ZIP -DestinationPath $extract

$ospath = "C:\OS\Windows11\sources\install.wim"
$mount = Read-Host -Prompt 'Please enter your path to use as a Mount point'


$Index3 = "Windows 11 Professional 25H2"

Write-Host "Processing: $Index3" -ForegroundColor Cyan
Mount-WindowsImage -ImagePath $ospath -Index 3 -Path $mount
Write-Host

reg load OfflineSoftware "$mount\Windows\System32\config\SOFTWARE"

reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "EnabledState" /t REG_DWORD /d 1 /f
reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "StateOptions" /t REG_DWORD /d 1 /f

cd "C:\downloads\Vivetool\extract"
.\ViVeTool.exe /disable /id:47205210 /image:"$mount\Windows"

Dismount-WindowsImage -Path "$mount" -Save

$Index6 = "Windows 11 Enterprise 25H2"

Write-Host "Processing: $Index6" -ForegroundColor Cyan
Mount-WindowsImage -ImagePath $ospath -Index 3 -Path $mount
Write-Host

reg load OfflineSoftware "$mount\Windows\System32\config\SOFTWARE"

reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "EnabledState" /t REG_DWORD /d 1 /f
reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "StateOptions" /t REG_DWORD /d 1 /f

cd "C:\downloads\Vivetool\extract"
.\ViVeTool.exe /disable /id:47205210 /image:"$mount\Windows"

Dismount-WindowsImage -Path "$mount" -Save

$Index12 = "Windows 11 Pro for Workstations 25H2"

Write-Host "Processing: $Index12" -ForegroundColor Cyan
Mount-WindowsImage -ImagePath $ospath -Index 3 -Path $mount
Write-Host

reg load OfflineSoftware "$mount\Windows\System32\config\SOFTWARE"

reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "EnabledState" /t REG_DWORD /d 1 /f
reg add "HKLM\OfflineSoftware\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "StateOptions" /t REG_DWORD /d 1 /f

cd "C:\downloads\Vivetool\extract"
.\ViVeTool.exe /disable /id:47205210 /image:"$mount\Windows"

Dismount-WindowsImage -Path "$mount" -Save
