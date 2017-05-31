[CmdletBinding()]
param(
	$Config
)

# pfx/p12 and cer/crt are supported
@($Config.Certificates) -ne $null | % {
    $CertificatePath = if (($Uri = [uri]$_.Url).Scheme) {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) $Uri.Segments[-1]
        Invoke-WebRequest -Uri $Uri -OutFile $tmp
        $tmp
    } else {
        Join-Path $Config._Path $_.File
    }
	
    $Cert = switch -Regex ($CertificatePath) {
		'(pfx|p12)$' {
			Push-Location $PSScriptRoot\openssl
			$Password = $_.Password -join '' | cmd '/c openssl enc -base64 -d | openssl rsautl -inkey private.pem -decrypt'
			# keyStorageFlag = 18 : 'MachineKeySet' - 2,'Exportable' - 4,'PersistKeySet' - 16
			New-Object Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath,$Password,18)
			Pop-Location
		}
		'(cer|crt)$' {
			New-Object Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
		}
	}
    foreach ($Store in $_.Store) {
	    $StoreLocation, $StoreName = $Store -split '\\'
	    $CertStore = New-Object Security.Cryptography.X509Certificates.X509Store($StoreName, $StoreLocation)
	    Write-Verbose "Installing certificate $($_.File) into $Store"
	    $CertStore.Open('ReadWrite')
	    $CertStore.Add($Cert)
	    $CertStore.Close()
    }
    if ($tmp -and (Test-Path $tmp)) { Remove-Item $tmp }
}