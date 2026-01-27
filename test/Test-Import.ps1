<#
    Test script for importing KeePass 2 secrets into your PowerPass locker.
    Copyright 2023-2026 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

if( $PSVersionTable.PSVersion.Major -ne 5 ) {
	throw 'This script requires PowerShell 5.'
}
Import-Module PowerPass
$p = Get-PowerPass
if( $p ) {
	if( $p.Implementation -ne 'DPAPI') {
		throw 'This test module is for the DP API edition of PowerPass.'
	}
} else {
	throw 'PowerPass is not installed. Run Deploy-PowerPass.ps1'
}
Clear-PowerPassLocker -Force
$path = Join-Path -Path $PSScriptRoot -ChildPath "kpdb-import.kdbx"
$db = Open-PowerPassDatabase -Path $path -MasterPassword (ConvertTo-SecureString "12345" -AsPlainText -Force)
Import-PowerPassSecrets -Database $db
Read-PowerPassSecret | select Title | Format-Table