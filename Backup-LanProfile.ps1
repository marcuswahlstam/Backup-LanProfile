<#
Created:    2018-08-31
Updated:    2018-08-31
Version:    1.0
Author :    Marcus Wahlstam
Company:    Advitum AB

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and
is not supported by the author

Updates
1.0 - Initial release

License:
The MIT License (MIT)

Copyright (c) 2018 Marcus Wahlstam, Advitum AB

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>


# Set where to save the connection profile (do not save anywhere in $env:windir)
$profileBackupPath = "$env:SystemDrive\Temp\LanProfile_1803"

# Create above path if it not exists
if (!(Test-Path $profileBackupPath)){New-Item $profileBackupPath -ItemType Directory -Force}

# Export the connection profile for LAN
netsh lan export profile folder="$profileBackupPath"

# Get the full filename for the LanProfile, assumes the LanProfile file is the only file in the folder
$lanProfilePath = (Get-ChildItem $profileBackupPath).FullName

# Get the content of the original SetupCompleteTemplate.cmd
$templateContent = Get-Content "$env:WINDIR\CCM\SetupCompleteTemplate.cmd"

# Set the commands to add to SetupCompleteTemplate.cmd
$newTemplateContent = (
"@echo off",
"echo --- Running custom tasks ---", 
"netsh lan add profile filename=`"$lanProfilePath`"", 
"REG ADD HKLM\System\CurrentControlSet\services\RasMan\PPP\EAP\13 /t REG_DWORD /v NoRevocationCheck /d 1 /f > nul 2>&1", 
"powershell.exe -ExecutionPolicy ByPass -NoProfile -Command `"&{Restart-NetAdapter -Name `'*`'}`"",
"echo Releasing IP address",
"ipconfig /release > nul 2>&1", 
"TIMEOUT /T 5 /NOBREAK",
"echo Renewing IP address", 
"ipconfig /renew > nul 2>&1", 
"TIMEOUT /T 5 /NOBREAK",
"echo IP-address is now:",
"powershell.exe -ExecutionPolicy ByPass -NoProfile -Command `"&{(Get-NetAdapter | where {`$_.status -eq `'Up`'} | Get-NetIPAddress).IPv4Address}`"",
"echo --- Done running custom tasks ---"
)

# Write new content to SetupCompleteTemplate.cmd, first the new content, then the original
Set-Content "$env:WINDIR\CCM\SetupCompleteTemplate.cmd" -Value $newTemplateContent, $templateContent
