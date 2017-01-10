[CmdletBinding()]
param(
	$Config
)

$Computer = [ADSI]"WinNT://$env:COMPUTERNAME,computer"

@($Config.Groups) -ne $null | % {
	$Group = $Computer.Create('Group', $_)
	$Group.SetInfo()
}

@($Config.Users) -ne $null | % {
    if ($_.OldName) {
        $User = [ADSI]"WinNT://$env:COMPUTERNAME/$($_.OldName),user"
        $User.Rename($_.Name) # PSBase
    } else {
	    $User = $Computer.Create('User', $_.Name)
    }
    if ($_.Password) {
	    $User.SetPassword($_.Password)
    }
	$User.SetInfo()
	@($_.Groups) -ne $null | % {
		try {
			$Group = [ADSI]"WinNT://$env:COMPUTERNAME/$_,group"
			$Group.Add("WinNT://$($User.Name),user")
		} catch {
			throw "Cannot add $($User.Name) to $_ - group not found"
		}
	}
}