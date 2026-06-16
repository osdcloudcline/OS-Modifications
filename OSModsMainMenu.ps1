Function Show-MainMenu{ 
    [CmdletBinding()]
    param(
    [string]$Title = 'OS WIM File Modifications - Main Menu',
    [string]$Question = 'What type of action do you want to perform?'
)
cls

Write-Host "======= $Title ======"
Write-Host " 1. Add Drivers to WIM File"
Write-Host " 2. Add Features to WIM File"
Write-Host " 3. Extract a WIM File from the original install.wim"
Write-Host " 4. Add Offline WIM File Registry modifications"
Write-Host " 5. Add Updates to the WIM File"
Write-Host " 6. Configure Windows 11 Enterprise Edition for gaming in the offline mounted WIM File"
Write-Host " 7. Return to Main Menu"

do 
{
  $selection = Read-Host 'Please choose an option'
  switch($selection)
  {

  '1' { cls
        $Drivers = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Drivers/Drivers.ps1")
        Invoke-Expression $($Drivers.Content)
        }
  '2' { cls
        $FeaturesSM = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Features/Client%20OS%20Features/Disable-NewStartMenu.ps1")
        Invoke-Expression $($FeaturesSM.Content)

        pause

        $FeaturesRSAT = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Features/Client%20OS%20Features/Offline-RSAT-Integration.ps1")
        Invoke-Expression $($FeaturesRSAT.Content)
        }
  '3' { cls
        $ExtractWIM = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Image%20Extraction/WIMExtract.ps1")
        Invoke-Expression $($ExtractWIM.Content)
        }
  '4' { cls
        $Registry = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Registry/Registry.ps1")
        Invoke-Expression $($Registry.Content)
        }   
  '5' { cls
        $Updates = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Updates/Updates.ps1")
        Invoke-Expression $($Updates.Content)
        }
  '6' { cls
        $EnterpriseEditionGaming = Invoke-WebRequest("https://github.com/osdcloudcline/OS-Modifications/raw/refs/heads/main/Gaming/TuneForGaming.ps1")
        Invoke-Expression $($EnterpriseEditionGaming.Content)
        }
  '7' { cls
        $Main = Invoke-WebRequest("")
        Invoke-Expression $($Main.Content)
        }
    }
    }
     until ($selection -eq '7'){Invoke-Expression $($Main.Content)}
}
Show-MainMenu
