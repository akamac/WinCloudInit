[CmdletBinding()]
param(
	$Config
)

Write-Verbose 'Extending existing volumes'
'rescan' | diskpart
(Get-CimInstance -Class Win32_Volume -Property Name).Name -match ':' | % {
	"select volume $_",'extend' | diskpart
}

# config source here! check plugin execution order
Write-Verbose 'Changing drive letter for CDROM'
'select volume 0','assign letter=Z' | diskpart

Write-Verbose 'Formatting and mounting additional disks'
$DiskDrives = Get-CimInstance -Class Win32_DiskDrive -Property Index,SerialNumber,Partitions
$LogicalDisks = Get-CimInstance Win32_LogicalDisk -Property DeviceID
$i = 0
$UnassignedLetters = [char[]](68..90) | ? { $_ -notin $LogicalDisks.DeviceID.TrimEnd(':') }
$Config.HDD | % {
	$HDD = $DiskDrives | ? SerialNumber -eq $_.Uuid
	if (-not $HDD.Partitions) {
		$Index = $HDD.Index
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
	}
}