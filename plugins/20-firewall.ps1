[CmdletBinding()]
param(
	$Config
)

if ($Config.Firewall.Disabled) {
	Write-Verbose 'Disabling firewall'
	#Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
	netsh advfirewall set allprofiles state off
}