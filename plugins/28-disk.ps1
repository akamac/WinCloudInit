[CmdletBinding()]
param(
	$Config
)

Write-Verbose 'Extending existing volumes'
'rescan' | diskpart
(Get-CimInstance -Class Win32_Volume -Property Name -Verbose:$false).Name -match ':' | % {
	"select volume $_",'extend' | diskpart
}

# config source here! check plugin execution order
Write-Verbose 'Changing drive letter for CDROM'
'select volume 0','assign letter=Z' | diskpart

Write-Verbose 'Formatting and mounting additional disks'
$DiskProperties = 'Index','SerialNumber','Partitions','SCSIBus','SCSILogicalUnit'
$DiskDrives = Get-CimInstance -Class Win32_DiskDrive -Property $DiskProperties -Verbose:$false
$LogicalDisks = Get-CimInstance Win32_LogicalDisk -Property DeviceID -Verbose:$false
$i = 0
$UnassignedLetters = [char[]](68..90) | ? { $_ -notin $LogicalDisks.DeviceID.TrimEnd(':') }
foreach ($HDD in $Config.HDD) {
	$Bus, $Lun = $HDD.DeviceNode -replace 'scsi' -split ':'
	$HardDisk = $DiskDrives |
	? { $_.SerialNumber -eq $HDD.Uuid -or ($_.SCSIBus -eq $Bus -and $_.SCSILogicalUnit -eq $Lun)}
	$Index = $HardDisk.Index
	if (-not $HardDisk.Partitions) {
		$MountPoint = if ($_.MountPoint) { $_.MountPoint } else { $UnassignedLetters[$i] + ':'; $i++ }
		$Label = if ($_.Label) { $_.Label } else { 'Data' }
		$ClusterSizeKB = if ($_.ClusterSizeKB) { "$($_.ClusterSizeKB)K" } else { '4K' }
		mkdir $MountPoint -ea SilentlyContinue
		Write-Verbose "Index: $Index, MountPoint: $MountPoint, Label: $Label, Cluster Size: $ClusterSizeKB"
		"select disk $Index",
		'attributes disk clear readonly',
		'online disk',
		'convert gpt',
		'create partition primary',
		"format label='$Label' fs=ntfs unit=$ClusterSizeKB quick",
		"assign mount='$MountPoint'" | diskpart
	} else {
		# disks are offline after sysprep ('SAN POLICY=OnlineAll')
		"select disk $Index",
		'online disk' | diskpart
	}
}