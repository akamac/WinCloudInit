# WinCloudInit
*CloudInit for Windows*

WinCloudInit provides a framework for early guest (Windows) initialization 
similar to [CloudInit](http://cloudinit.readthedocs.io/en/latest/).
In VMware and Hyper-V environments it replaces guest customization with 
more flexible and extendable mechanism.
Compared to [CloudbaseInit](https://cloudbase.it/cloudbase-init/) it's 
written purely on PowerShell.

List of bundled plugins:
- 01-sysprep.ps1
- 04-network.ps1
- 08-hostname.ps1
- 10-posh.ps1
- 11-cert.ps1
- 12-winrm.ps1
- 16-rdp.ps1
- 20-firewall.ps1
- 24-activation.ps1
- 28-disk.ps1
- 32-user.ps1

Currently the only supported config source is cloud-config.json file stored on floppy/cdrom:
```
{
  "HostName": "WINCLOUDINIT",
  "HDD": [
    {
      "Capacity": 50
    },
    {
      "Capacity": 100,
      "Label": "Data",
      "MountPoint": "C:\data",
      "ClusterSizeKB": 64
    }
  ],
  "NIC": [
    {
      "Ip": [
        "10.240.157.10/24",
        "10.240.157.11/24"
      ],
      "Gw": "10.240.157.1",
      "Name": "PrivateConnection",
      "Mac": "00:50:56:96:1d:27"
    },
    {
      "Ip": [
        "10.250.157.10/24",
      ],
      "Name": "PrivateConnection2",
      "Mac": "00:50:56:96:1d:28"
    }
  ],
  "DNS": [ "8.8.8.8" ],
  "Sysprep": {
    "Org": "Company",
    "Owner": "SysAdmin",
    "TimeZone": "PST",
    "AdminPassword": "P@$$w0rd"
  },
  "ProductKey": "D2N9P-3P6X9-2R39C-7RTCD-MDVJX",
  "WinRM": {
    "Https": true,
    "Certificate": "812FF641630C82CFC1104597409DB086FA43E480"
  },
  "ExecutionPolicy": "Restricted",
  "RDP": false,
  "Firewall": {
    "Disabled": false
  },
  "Certificates": [
    {
      "FileName": "wincloudinit-winrm.pfx",
      "Store": "LocalMachine\\My",
      "Password": "certpass"
    },
    {
      "FileName": "GeoTrust Global CA.cer",
      "Store": "LocalMachine\\CA"
    }
  ],
  "Groups": [ "PowerUsers" ],
  "Users": [
    {
      "Name": "superuser",
      "Password": "c0mplek$P@$$",
      "Groups": [ "PowerUsers", "Administrators" ]
    }
  ]
}
```

To install the module:
- download from GitHub and place into 'C:\Program Files\WindowsPowerShell\Modules' 
(requires system-wide location)
- OR grab it from PowerShell Gallery with `Install-Module WinCloudInit -Scope AllUsers`

To enable WinCloudInit upon system reboot run `Set-WinCloudInit -Enabled`, you will 
be prompted for Administrator credentials (after sysprep module will switch to SYSTEM 
account).

Log is stored in C:\Windows\Temp\WinCloudInit-#date#.log

The module targets PowerShell v4 installations and has been tested on:
- Windows Server 2008 R2
- Windows Server 2012 R2

## For developers
To develop a new plugin write a PowerShell script that starts with:
```
[CmdletBinding()]
param(
	$Config
)
```
Inject the neccessary configuration data in cloud-config.json so it is exposed 
to your source through `$Config` variable. *Prepend the name 
with double-digit number* according to the order when the plugin is intended 
to be run and put it into the *plugins* folder.  
If your plugin is going to reboot the system, prior to restart send **'reboot'** 
string to stdout so the module can suspend execution of the next plugin 
and resume after system has been restarted. To handle reboots the module keeps 
a state file in the module directory where it stores a current execution step.
To reset the state run `Set-WinCloudInit -ResetState`