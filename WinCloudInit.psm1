function Set-WinCloudInit {
	param(
		[switch] $Enabled,
		[switch] $ResetState,
		[pscredential] $Credential
	)

	if ($ResetState) {
		Set-Content $PSScriptRoot\state ''
	}

	if ($PSBoundParameters.ContainsKey('Enabled')) {
		if ($Enabled) {
			Set-WinCloudInit -Enabled:$false -ResetState
			if (-not $Credential) {
				$Credential = Get-Credential -UserName $env:USERNAME -Message 'Specify credential'
			}
			$user = $Credential.UserName
			$password = $Credential.GetNetworkCredential().Password
			$command = 'powershell -Command Start-WinCloudInit'
			schtasks /Create /TN 'WinCloudInit' /RU $user /RP $password /TR $command /SC ONSTART
		} else {
			if (schtasks | Select-String WinCloudInit) {
				schtasks /Delete /TN 'WinCloudInit' /F
			}
		}
	} elseif ($Credential.UserName -eq 'SYSTEM') {
		schtasks /Change /TN 'WinCloudInit' /RU 'SYSTEM'
	}
}

function Start-WinCloudInit {
	$Log = Join-Path C:\Windows\Temp "WinCloudInit-$((Get-Date).ToString('MM-dd-yy')).log"

	"Starting WinCloudInit $(Get-Date)" >> $Log
	'Searching for cloud-config.json (floppy/cdrom)' >> $Log
	2,5 | % {
		if ($ConfigDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = $_" -Property DeviceID) {
			$ConfigPath = Join-Path $ConfigDrive.DeviceID 'cloud-config.json'
			if (Test-Path $ConfigPath) {
				$Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json |
				Add-Member -MemberType NoteProperty -Name _Path -Value (Split-Path $ConfigPath) -TypeName string -Force -PassThru
				"Found in $ConfigPath" >> $Log
				return
			}
		}
	}
	if (-not $Config) {
		$Msg = 'No config source found'
		$Msg >> $Log
		throw $Msg
	}

	# state file contains last executed plugin number (for reboot handling)
	'Reading <state> file' >> $Log
	$StatePath = "$PSScriptRoot\state"
	try {
		if (-not (Test-Path $StatePath)) {
			New-Item -Path $StatePath -ItemType File
		}
		$State = [int](Get-Content $StatePath)
		"State is $State" >> $Log
	} catch {
		$Msg = 'Invalid state file content'
		$Msg >> $Log
		throw $Msg
	}

	'Running plugins:' >> $Log
	Get-ChildItem $PSScriptRoot\plugins | Sort Name |
	? { ($_.Name.Split('-')[0] -as [int]) -gt $State } -pv Plugin | % {
		try {
			"Executing $($Plugin.Name)" >> $Log
			$Output = & $Plugin.FullName -Config $Config -Verbose 4>> $Log
		} catch {
			$Msg = "Error during $($Plugin.Name) execution"
			($_ | Out-String) >> $Log
			throw $Msg
		}
		$Plugin.Name.Split('-')[0] > $StatePath
		if (($Output | Select -Last 1) -eq 'reboot') { break } # exit function, continue after reboot
	}
	
	'Disabling WinCloudInit' >> $Log
	Set-WinCloudInit -Enabled:$false
}