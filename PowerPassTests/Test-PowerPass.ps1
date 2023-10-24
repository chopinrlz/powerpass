Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}

function Assert-Strings {
    param(
        $StringA,
        $StringB
    )
    if( [String]::Equals( $StringA, $StringB, "Ordinal" ) ) {
        Write-Host "Assert passed"
    } else {
        Write-Warning "Assert failed"
    }
}

# Master password for all test cases
$secureString = ConvertTo-SecureString -String "12345" -AsPlainText -Force

Write-Host "Testing a Database with a Password: " -NoNewline
$expectedPassword = "BkLQzZvxEV5Znav7"
$database = Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithPassword.kdbx" -MasterPassword $secureString
$secret = Get-PowerPassSecret -Database $database -Title "Test Entry"
$actualPassword = $secret.Password
Assert-Strings -StringA $expectedPassword -StringB $actualPassword

Write-Host "Testing a Database with a Key File: " -NoNewline
$expectedPassword = "C4uqg38rjAdoo1AT"
$database = Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithKeyFile.kdbx" -KeyFile "$PSScriptRoot\DatabaseKeyFile.keyx"
$secret = Get-PowerPassSecret -Database $database -Title "Test Entry"
$actualPassword = $secret.Password
Assert-Strings -StringA $expectedPassword -StringB $actualPassword

# Cannot be done for anyone else but yourself
# Write-Host "Testing a Database with User Account: " -NoNewline
# $expectedPassword = "3ZUVBh2SA4pnmk5R"
# $database = Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithUserAccount.kdbx" -WindowsUserAccount
# $secret = Get-PowerPassSecret -Database $database -Title "Test Entry"
# $actualPassword = $secret.Password
# Assert-Strings -StringA $expectedPassword -StringB $actualPassword

Write-Host "Testing a Database with a Key File and Password: " -NoNewline
$expectedPassword = "trlasJhJlVuZHETS"
$database = Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithKeyFileAndPassword.kdbx" -KeyFile "$PSScriptRoot\DatabaseKeyFile.keyx" -MasterPassword $secureString
$secret = Get-PowerPassSecret -Database $database -Title "Test Entry"
$actualPassword = $secret.Password
Assert-Strings -StringA $expectedPassword -StringB $actualPassword