if( $PSVersionTable.PSVersion.Major -lt 7 ) {
    throw "TPM support is for PowerShell 7"
}
if( -not $IsLinux ) {
    throw "TPM support is for the Linux OS"
}
Set-Location $PSScriptRoot
if( Test-Path "powerpasstpm.o" ) { Remove-Item "powerpasstpm.o" -Force }
if( Test-Path "libpptpm.so" ) { Remove-Item "libpptpm.so" -Force }
& gcc @('-c','-fPIC','powerpasstpm.c','-o','powerpasstpm.o')
& gcc @('-shared','powerpasstpm.o','-o','libpptpm.so')
$source = Get-Content "$PSScriptRoot/TpmProvider.cs" -Raw
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Runtime.InteropServices"
$provider = New-Object "PowerPass.TpmProvider"
Write-Output "Invoking test function"
$provider.Test()
Write-Output "Invoking version function"
$provider.Version()