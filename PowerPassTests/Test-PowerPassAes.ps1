Write-Host "This test script will test the AES implementation of PowerPass"
Write-Host "These tests should pass in both Windows PowerShell and PowerShell 7 on all operating systems"
Write-Host "Testing module import"
Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}
if( $PowerPass.Implementation -ne "AES" ) {
    throw "This test is for the AES implementation of PowerPass, you have the $($PowerPass.Implementation) implementation installed"
}

Write-Host "Testing Read-PowerPassSecret"
Read-PowerPassSecret | ? Title -eq "Default"

Write-Host "Testing Write-PowerPassSecret"
Write-PowerPassSecret -Title "Unit Test"

Write-Host "Testing Read-PowerPassSecret"
Read-PowerPassSecret | ? Title -eq "Unit Test"

Write-Host "Testing Clear-PowerPassLocker"
Clear-PowerPassLocker

Write-Host "Testing Read-PowerPassSecret"
Read-PowerPassSecret | ? Title -eq "Default"

Write-Host "Testing Export-PowerPassLocker"
Write-PowerPassSecret -Title "Unit Test"
Export-PowerPassLocker "$PSScriptRoot\export.locker"

Write-Host "Testing Import-PowerPassLocker"
Import-PowerPassLocker "$PSScriptRoot\export.locker"
Read-PowerPassSecret | ? Title -eq "Unit Test"

Write-Host "Testing New-PowerPassRandomPassword"
New-PowerPassRandomPassword

Write-Host "Testing Update-PowerPassKey"
Update-PowerPassKey