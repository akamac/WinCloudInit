[CmdletBinding()]
param(
    $Config
)

$Computer = [ADSI]"WinNT://$env:COMPUTERNAME,computer"

@($Config.Groups) -ne $null | % {
    $Group = $Computer.Create('Group', $_)
    Write-Verbose "Creating group $_"
    $Group.SetInfo()
}

@($Config.Users) -ne $null | % {
    if ($_.OldName) {
        $User = [ADSI]"WinNT://$env:COMPUTERNAME/$($_.OldName),user"
        Write-Verbose "Renaming user $($_.OldName) to $($_.Name)"
        $User.Rename($_.Name) # PSBase
    } else {
        Write-Verbose "Checking if user $($_.Name) exists"
        $UserName = $_.Name
        try {
            $User = [ADSI]"WinNT://$env:COMPUTERNAME/$($_.Name),user"
        } catch {
            Write-Verbose "Creating user $UserName"
            $User = $Computer.Create('User', $UserName)
        }
    }
    if ($_.Password) {
        Push-Location $PSScriptRoot\openssl
        $pass = $_.Password -join '' | cmd '/c openssl enc -base64 -d | openssl rsautl -inkey private.pem -decrypt'
        Write-Verbose "Setting password for user $($_.Name)"
        $User.SetPassword($pass)
        Pop-Location
    }
    $User.SetInfo()
    @($_.Groups) -ne $null | % {
        try {
            $Group = [ADSI]"WinNT://$env:COMPUTERNAME/$_,group"
            Write-Verbose "Adding user $($User.Name) to group $_"
            $Group.Add("WinNT://$($User.Name),user")
        } catch {
            throw "Cannot add $($User.Name) to $_ - group not found"
        }
    }
}