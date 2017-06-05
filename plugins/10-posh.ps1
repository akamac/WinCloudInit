[CmdletBinding()]
param(
    $Config
)

if ($Config.ExecutionPolicy) {
    Write-Verbose "Setting ExecutionPolicy to $($Config.ExecutionPolicy)"
    Set-ExecutionPolicy $Config.ExecutionPolicy -Scope LocalMachine -Force
}