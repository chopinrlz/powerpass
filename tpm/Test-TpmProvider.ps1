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
& make clean
& make
$payload = Get-Content .\Payload.cs -Raw
Add-Type -TypeDefinition $payload -Language CSharp
[string[]]$tpmInfo = & ./powerpasstpm test
$result = [PowerPass.TpmResult]::new( $tpmInfo )
if( $result.ResultCode -ne 0 ) {
    Write-Output "Error: $($result.ResultCode)"
    Write-Output "Message: $($result.Message)"
} else {
    $tpm = ConvertFrom-Json ($result.Payload)
    $tpm | Get-Member
}