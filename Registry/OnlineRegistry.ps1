$HKCRREG1 = "Add Copy To Move To"



Write-Host "Importing $HKCRREG1...." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKCRREG1..." -Verbose
reg add "HKLM\SYSTEM\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /v "Copy To" /f
reg add "HKLM\SYSTEM\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\{C2FBB631-2971-11D1-A18C-00C04FD75D13}" /v "Move To" /f




$HKCRREG2 = "Add Safe Mode"



Write-Host "Importing $HKCRREG2..." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKCRREG2..." -Verbose


reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode" /v "icon" /t REG_SZ /d "bootux.dll,-1032" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode" /v "MUIVerb" /t REG_SZ /d "Safe Mode" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode" /v "Position" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode" /v "SubCommands" /t REG_SZ /d "" /f

reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\001-NormalMode" /ve /t REG_SZ /d "Restart in Normal Mode" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\001-NormalMode" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\001-NormalMode\command" /ve /t REG_SZ /d "powershell -windowstyle hidden -command Start-Process cmd -ArgumentList '/c bcdedit /deletevalue {default} safeboot & bcdedit /deletevalue {default} safebootalternateshell & shutdown -r -t 00 -f' -Verb runAs" /f

reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\002-SafeMode" /ve /t REG_SZ /d "Restart in Safe Mode" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\002-SafeMode" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\002-SafeMode\command" /ve /t REG_SZ /d --% "powershell -windowstyle hidden -command Start-Process cmd -ArgumentList '/s' , '/c' , 'bcdedit /set {default} safeboot minimal & bcdedit /deletevalue {default} safebootalternateshell & shutdown -r -t 00 -f' -Verb runAs" /f

reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\003-SafeModeNetworking" /ve /t REG_SZ /d "Restart in Safe Mode with Networking" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\003-SafeModeNetworking" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\003-SafeModeNetworking\command" /ve /t REG_SZ /d "powershell -WindowStyle Hidden -Command Start-Process cmd -ArgumentList '/c bcdedit /set {default} safeboot network && bcdedit /deletevalue {default} safebootalternateshell && shutdown -r -t 00 -f' -Verb RunAs" /f

reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\004-SafeModeCommandPrompt" /ve /t REG_SZ /d "Restart in Safe Mode with Command Prompt" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\004-SafeModeCommandPrompt" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\DesktopBackground\Shell\SafeMode\shell\004-SafeModeCommandPrompt\command" /ve /t REG_SZ /d "powershell -windowstyle hidden -command \`"Start-Process cmd -ArgumentList '/c bcdedit /set {default} safeboot minimal && bcdedit /set {default} safebootalternateshell yes && shutdown -r -t 00 -f' -Verb runAs\`"" /f


$HKLMREG1 = "Adobe Master Collection Suite"

Write-Host "Importing $HKLMREG1..." -ForegroundColor Cyan
Write-Host 
Write-Verbose "Adding $HKLMREG1..." -Verbose

reg load HKLM\SOFTWARE "$Mount\Windows\System32\config\SOFTWARE"

reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cCloud" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultExecMenuItems" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultFindAttachmentPerms" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchAttachmentPerms" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cSharePoint" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cWebmailProfiles" /f

reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cCloud" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cIPM" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cSharePoint" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cWebmailProfiles" /f

reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cCloud" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cIPM" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cSharePoint" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cWebmailProfiles" /f

reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultExecMenuItems" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultFindAttachmentPerms" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchAttachmentPerms" /f
reg add "HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cDefaultLaunchURLPerms" /f



$HKLMREG2 = "Google Chrome AI"

Write-Host "Adding $HKLMREG2..." -ForegroundColor Cyan
Write-Host 



reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "GenAILocalFoundationalModelSettings" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "GenAiDefaultSettings" /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "AIModeSettings" /t REG_DWORD /d 1 /f



$HKSYSTEMREG1 = "Disable BitLocker Device Encryption"


Write-Host "Importing $HKSYSTEMREG1...." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKSYSTEMREG1..." -Verbose
reg add "HKLM\SYSTEM\ControlSet001\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f




$HKLMSYSTEMREG2 = "Disable Windows Defender"



Write-Host "Importing $HKLMSYSTEMREG2..." -ForegroundColor Cyan
Write-Host
Write-Verbose "Adding $HKLMSYSTEMREG2..." -Verbose

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f 

reg add "HKLM\SYSTEM\ControlSet001\Services\WinDefend" /v Start /t REG_DWORD /d 4 /f


reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "EnabledState" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\FeatureManagement\Overrides\0\47205210" /v "StateOptions" /t REG_DWORD /d 1 /f
