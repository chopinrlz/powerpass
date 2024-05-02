Import-Module PowerPass
Clear-PowerPassLocker -Force
$path = Join-Path -Path $PSScriptRoot -ChildPath "kpdb-import.kdbx"
$db = Open-PowerPassDatabase -Path $path -MasterPassword (ConvertTo-SecureString "12345" -AsPlainText -Force)
Import-PowerPassSecrets -Database $db
Read-PowerPassSecret | select Title | Format-Table