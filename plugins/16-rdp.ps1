[CmdletBinding()]
param(
    $Config
)

if ($Config.RDP) {
    Write-Verbose 'Allow RDP'
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
    Write-Verbose 'Enable Network Level Authentication'
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
    Write-Verbose 'Configuring firewall RDP exception'
    #Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
    netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes
}