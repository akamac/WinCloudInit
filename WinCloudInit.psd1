@{
    RootModule = 'WinCloudInit.psm1'
    ModuleVersion = '1.3.10'
    GUID = '5f24b005-82e2-4d16-8470-51c1851f5562'
    Author = 'Alexey Miasoedov'
    CompanyName = 'Intermedia'
    Copyright = '(c) 2018 Alexey Miasoedov. All rights reserved.'
    Description = 'CloudInit module for Windows'
    PowerShellVersion = '4.0'
    FunctionsToExport = 'Set-WinCloudInit','Start-WinCloudInit'
    FileList = 
        'WinCloudInit.psm1',
        'plugins\01-reboot.ps1',    
        'plugins\02-sysprep.ps1',
        'plugins\03-hostname.ps1',
        'plugins\04-network.ps1',
        'plugins\09-user.ps1',
        'plugins\10-posh.ps1',
        'plugins\11-cert.ps1',
        'plugins\12-winrm.ps1',
        'plugins\16-rdp.ps1',
        'plugins\20-firewall.ps1',
        'plugins\24-activation.ps1',
        'plugins\28-disk.ps1',
        'plugins\makecert.exe',
        'plugins\unattend_2K16.xml',
        'plugins\unattend_2K12R2.xml',
        'plugins\unattend_2K8R2.xml',
        'plugins\openssl\libeay32.dll',
        'plugins\openssl\openssl.exe',
        'plugins\openssl\ssleay32.dll'
    PrivateData = @{
        PSData = @{
            Tags = @('Cloud-Init','CloudInit','Windows')
            #LicenseUri = 'https://github.com/akamac/GitLabProvider/blob/master/LICENSE'
            ProjectUri = 'https://github.com/akamac/WinCloudInit'
            ReleaseNotes = 'A framework for early guest (Windows) initialization.'
        }
    }
}