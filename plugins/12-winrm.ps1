[CmdletBinding()]
param(
	$Config
)

if ($Config.WinRM) {
	#Write-Verbose 'Enabling WinRM'
	#Enable-PSRemoting -Force | Out-Null
	if ($Config.WinRM.Https) {
		if (-not $Config.WinRM.Certificate) {
			Write-Verbose 'Generating and installing self-signed certificate'
			#$Cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
			$Param = 
				'-r',
				'-n',"CN=$env:COMPUTERNAME",
				'-sk',"$env:COMPUTERNAME",
				'-sr','localmachine',
				'-ss','my',
				'-a','sha256',
				'-eku','1.3.6.1.5.5.7.3.1',
				'-sky','exchange',
				'-sp','Microsoft RSA SChannel Cryptographic Provider',
				'-sy','12'
			& $PSScriptRoot\makecert.exe $Param
			$Cert = Get-Item Cert:\LocalMachine\My\* | ? {
				$_.Subject -eq "CN=$env:COMPUTERNAME" -and
				$_.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.1'
			}
		} else {
			try {
				$Cert = Get-Item Cert:\LocalMachine\My\$($Config.WinRM.Certificate)
			} catch {
				throw "Cannot find certificate with thumbprint $($Config.WinRM.Certificate)"
			}
		}
		Write-Verbose 'Configuring HTTPS WinRM listener'
		winrm create winrm/config/Listener?Address=*+Transport=HTTPS @"
@{Hostname="$env:COMPUTERNAME";CertificateThumbprint="$($Cert.Thumbprint)";Port="5986"}
"@
	}
	#winrm quickconfig -transport:https
	#winrm enumerate winrm/config/listener
	Write-Verbose 'Configuring firewall WinRM exception'
	#Enable-NetFirewallRule -DisplayGroup 'Windows Remote Management'
	netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes
}