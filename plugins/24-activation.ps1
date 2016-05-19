[CmdletBinding()]
param(
	$Config
)

if ($Config.ProductKey) {
	Write-Verbose 'Setting product key'
	slmgr /ipk $Config.ProductKey
	Write-Verbose 'Activating Windows'
	slmgr /ato
}