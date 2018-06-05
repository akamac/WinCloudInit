[CmdletBinding()]
param(
    $Config
)

if ($Config.WinRM) {
    #Write-Verbose 'Enabling WinRM'
    #Enable-PSRemoting -Force | Out-Null
    #winrm quickconfig -transport:https
    #winrm enumerate winrm/config/listener
    Write-Verbose 'Configuring firewall WinRM exception'
    #Enable-NetFirewallRule -DisplayGroup 'Windows Remote Management'
    netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes
    if ($Config.WinRM.Https) {
        if (-not $Config.WinRM.Certificate) {
            Write-Verbose 'Generating and installing self-signed certificate'
            #$Cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME
            $SerialNumber = Get-Random -Minimum 1 -Maximum ([int]::MaxValue)
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
                '-sy','12',
                '-#',$SerialNumber
            & $PSScriptRoot\makecert.exe $Param
            $Cert = Get-Item Cert:\LocalMachine\My\* | ? SerialNumber -match ('0*{0:X}' -f $SerialNumber)
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
        if ($UserMapping = $Config.WinRM.UserMapping) {
            Write-Verbose 'Enabling certificate-based authentication'
            Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
            $UserMapping | Get-Member -MemberType Properties | % {
                $User = $_.Name
                $CertThumbPrint = $UserMapping.($_.Name)
                Push-Location $PSScriptRoot\openssl
                $PlainTextPassword = ($Config.Users | ? Name -eq $User).Password -join '' |
                cmd '/c openssl enc -base64 -d | openssl rsautl -inkey private.pem -decrypt'
                $Password = ConvertTo-SecureString $PlainTextPassword -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential($User,$Password)
                Pop-Location
                Write-Verbose "Creating user mapping for $User, cert thumbprint $CertThumbPrint"
                New-Item -Path WSMan:\localhost\ClientCertificate -Subject "$User@localhost" -URI * -Issuer $CertThumbPrint -Credential $Credential -Force
            }
        }
    }
}