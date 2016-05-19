[CmdletBinding()]
param(
	$Config
)

function ConvertTo-SubnetMask ([int]$SubnetMaskLength) {
    $SubnetMask = -1 -shl (32 - $SubnetMaskLength)
    $Bytes = [BitConverter]::GetBytes($SubnetMask)
    if ([BitConverter]::IsLittleEndian) {
        [array]::Reverse($Bytes)
    }
    [ipaddress]$Bytes
}

Write-Verbose 'Configuring networking'
@($Config.NIC) -ne $null | % -Begin {
	$i = 0
	Write-Verbose 'Disabling teredo/6to4/isatap'
	netsh int teredo set state disabled
	netsh int 6to4 set state disabled
	netsh int isatap set state disabled
} {
	Write-Verbose "Network adapter $($_.Mac)"
	$NetAdapter = Get-WmiObject -Class Win32_NetworkAdapter -Filter "MACAddress = '$($_.Mac)'"
	$ConnectionName = if ($_.Name) {$_.Name} else { "Connection$i" }
	$NetAdapter.NetConnectionID = $ConnectionName
	Write-Verbose "Setting connection name to $ConnectionName"
	$NetAdapter.Put()
	$NetAdapterConfig = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "Index = '$($NetAdapter.DeviceID)'"
	Write-Verbose "Configuring ip addresses $($_.Ip)"
	$NetAdapterConfig.EnableStatic(
		@($_.Ip.ForEach({ $_.Split('/')[0] })),
		@($_.Ip.ForEach({ ConvertTo-SubnetMask ($_.Split('/')[1]) }))
	)
	if ($_.Gw) {
		Write-Verbose "Setting gateway $($_.Gw)"
		$NetAdapterConfig.SetGateways($_.Gw)
		if ($Config.DNS) {
			Write-Verbose "Configuring DNS servers $($Config.DNS)"
			$NetAdapterConfig.SetDNSServerSearchOrder($Config.DNS)
		}
	}
	$i++
}