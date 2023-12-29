# Test script for libpptpm integration
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.

if( $PSVersionTable.PSVersion.Major -lt 7 ) {
    throw "TPM support is for PowerShell 7"
}
if( -not $IsLinux ) {
    throw "TPM support is for the Linux OS"
}
Set-Location $PSScriptRoot
if( -not (Test-Path "/usr/lib/libpptpm.so") ) { 
    throw "libpptpm not installed, run 'make' then 'sudo make install' from ./tpm directory"
}
$source = Get-Content "$PSScriptRoot/TpmProvider.cs" -Raw
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Runtime.InteropServices"
$provider = New-Object "PowerPass.TpmProvider"
Write-Output "Invoking test function"
$provider.Test()
Write-Output "Invoking version function"
$provider.Version()