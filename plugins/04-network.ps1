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
        if ($Config.DNS.Servers) {
            Write-Verbose "Configuring DNS servers $($Config.DNS.Servers)"
            #$NetAdapterConfig.SetDNSServerSearchOrder($Config.DNS.Servers)
            $Config.DNS.Servers | % -Begin { $idx = 0 } {
                netsh interface ipv4 add dnsservers name="$ConnectionName" address=$_ index=$idx validate=false
                $idx++
            }
        }
    }
    if ($Config.DNS.DomainSearch) {
        Write-Verbose "Setting domain search list $($Config.DNS.DomainSearch)"
        $DNSSuffixSearch = @($Config.Domain.Name) + $Config.DNS.DomainSearch -ne $null | Select -Unique
        ([wmiclass]'Win32_NetworkAdapterConfiguration').SetDNSSuffixSearchOrder($DNSSuffixSearch)
    }
    $i++
}