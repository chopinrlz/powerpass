# Test script for libpptpm integration
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.

if( $PSVersionTable.PSVersion.Major -lt 7 ) {
    throw "TPM support is for PowerShell 7"
}
if( -not $IsLinux ) {
    throw "TPM support is for the Linux OS"
}
Set-Location $PSScriptRoot
if( -not (Test-Path "powerpasstpm") ) {
    Write-Output "Compiling powerpasstpm using make"
    & make @('clean')
    & make
}

# Removed, for now, as no C# provider is required
# $source = Get-Content "$PSScriptRoot/TpmProvider.cs" -Raw
# Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Runtime.InteropServices"
# $provider = New-Object "PowerPass.TpmProvider"

$tpmInfo = & ./powerpasstpm @("test")
$tpmInfo = $tpmInfo -join ""
$tpm = ConvertFrom-Json $tpmInfo
$tpm | Get-Member