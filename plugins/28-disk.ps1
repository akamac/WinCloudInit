[CmdletBinding()]
param(
	$Config
)

if ($Config.HDD[0].Capacity) {
	Write-Verbose 'Extending system disk'
	'rescan','select volume C','extend' | diskpart
}

# config source here! check plugin execution order
Write-Verbose 'Changing drive letter for CDROM'
'select volume 0','assign letter=Z' | diskpart

$Config.HDD | Select -Skip 1 | % -Begin {
	Write-Verbose 'Formatting and mounting additional disks'
	$i = 1
	[char]$Letter = 'D'
} -Process {
	$MountPoint = if ($_.MountPoint) { $_.MountPoint } else { "${Letter}:"; $Letter = 1 + $Letter }
	$Label = if ($_.Label) { $_.Label } else { 'Data' }
	$ClusterSizeKB = if ($_.ClusterSizeKB) { "$($_.ClusterSizeKB)K" } else { '4K' }
	mkdir $MountPoint -ea SilentlyContinue
	Write-Verbose "MountPoint: $MountPoint, Label: $Label, Cluster Size: $ClusterSizeKB"
	'select disk $i',
	'attributes disk clear readonly',
	'online disk',
	'convert gpt',
	'create partition primary',
	"format label='$Label' fs=ntfs unit=$ClusterSizeKB quick",
	"assign mount='$MountPoint'" | diskpart
	$i++
}