# Backup-LanProfile

The Problem
Beginning with Windows 10 1703 there is a problem in the In-Place Upgrade (IUP) process (Windows 10 to Windows 10) that resets the 802.1x settings to default values, which causes problems for those using certificate-based authentication for their 802.1x. The computer will simply not authenticate. And to get the correct settings for 802.1x, the computer needs a working network connection to able to get these settings through Group Policy. A catch 22!
One solution could be to disable 802.1x during the upgrade, but that is not an acceptable solution in even a quite small organization. And security wise it’s a disaster.
We have come up with a solution that only involves adding a script to the Upgrade Task Sequence, the script is available to download in this blog post.

What the script does
1.	Saves the current and working connection profile to a file in the catalog specified in the script.
2.	Adds the following to the beginning of %WINDIR%\CCM\SetupCompleteTemplate.cmd
a.	Netsh command to add the connection profile back from the file saved in step 1.
b.	Adds a registry value so that RasMan (Remote Access Connection Manager) doesn’t do a revocation check on certificates. Quite hard without a network connection…
c.	Restart-NetAdapter so the above changes take effect.
d.	Ipconfig /release and /renew
e.	Prints out the IP-address (for troubleshooting)

What is SetupCompleteTemplate.cmd?
It’s a template for the script SetupComplete.cmd that runs at the very end of an IUP. If we had put it as a Task Sequence step after the Upgrade OS step, it would have been too late.
ConfigMgr makes sure that what’s in the template is run as SetupComplete.cmd in the Upgrade OS step. Read a more in-depth article about this at Gary Blok’s blog: https://garytown.com/customize-setupcomplete

The only thing you may want to change in the script is the path $profileBackupPath.

Add it to a Task Sequence
Create a package without a program that contains the script, then add a Run PowerShell Script step just before the Upgrade Operating System step.
