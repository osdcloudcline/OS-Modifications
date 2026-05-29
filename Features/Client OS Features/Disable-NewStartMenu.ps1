$Vivetool = "https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip"
$destination = "C:\downloads\Vivetool"
$ZIP = "C:\downloads\Vivetool\ViVeTool-v0.3.4-IntelAmd.zip"
$extract = "C:\downloads\Vivetool\extract"

Save-WebFile -SourceUrl $Vivetool -DestinationDirectory $destination

Expand-Archive -Path $ZIP -DestinationPath $extract


