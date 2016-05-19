[CmdletBinding()]
param(
	$Config
)

# pfx/p12 and cer/crt are supported
@($Config.Certificates) -ne $null | % {
	$CertificatePath = Join-Path $Config._Path $_.FileName
	$Password = $_.Password
	$StoreLocation, $StoreName = $_.Store -split '\\'
	$CertStore = New-Object Security.Cryptography.X509Certificates.X509Store($StoreName, $StoreLocation)
	$Cert = switch -Regex ($_.FileName) {
		'(pfx|p12)$' {
			# keyStorageFlag = 18 : 'MachineKeySet' - 2,'Exportable' - 4,'PersistKeySet' - 16
			New-Object Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath,$Password,18)
		}
		'(cer|crt)$' {
			New-Object Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
		}
	}
	Write-Verbose "Installing certificate $($_.FileName) into $($_.Store)"
	$CertStore.Open('ReadWrite')
	$CertStore.Add($Cert)
	$CertStore.Close()
}