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