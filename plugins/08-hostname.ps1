[CmdletBinding()]
param(
	$Config
)

# cannot rename domain machine
if ($Config.HostName -and 
	$env:COMPUTERNAME -ne $Config.HostName -and
	-not [System.Net.DNS]::GetHostByName('').HostName.Contains('.')) {
	Write-Verbose "Renaming computer to $($Config.HostName)"
	'reboot' # system will be rebooted
	Rename-Computer -NewName $Config.HostName -Restart -Force -Confirm:$false
}