<#
    Test script for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# First test is loading the PowerPass module
Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}

function Assert-Strings {
    <#
        .SYNOPSIS
        Compares two strings using case-sensitive Ordinal rules and writes Assert passed if they match or Assert failed if they do not match.
        .PARAMETER StringA
        The first string to compare.
        .PARAMETER StringB
        The second string to compare.
        .OUTPUTS
        This function does not output anything to the pipeline, but it writes to the host.
    #>
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

function Assert-Secret {
    <#
        .SYNOPSIS
        Locates the Test Entry secret from the spcified database and compares it with the expected password.
        .PARAMETER Database
        The PowerPass database object from Open-PowerPassDatabase.
        .INPUTS
        This function assumes that you have defined the variable $expectedPassword at the script scope and
        populated it with the currently expected password.
    #>
    param(
        [Parameter(ValueFromPipeline, Position = 0)]
        $Database
    )
    $secret = Get-PowerPassSecret -Database $Database -Match "Test Entry" -PlainTextPasswords
    $actualPassword = $secret.Password
    Assert-Strings -StringA $script:expectedPassword -StringB $actualPassword
}

# Master password for all test cases
$secureString = ConvertTo-SecureString -String "12345" -AsPlainText -Force

# Test a database which uses a password key
Write-Host "Testing a Database with a Password: " -NoNewline
$script:expectedPassword = "BkLQzZvxEV5Znav7"
Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithPassword.kdbx" -MasterPassword $secureString | Assert-Secret

# Test a database which uses a key file key
Write-Host "Testing a Database with a Key File: " -NoNewline
$script:expectedPassword = "C4uqg38rjAdoo1AT"
Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithKeyFile.kdbx" -KeyFile "$PSScriptRoot\DatabaseKeyFile.keyx" | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses the Windows user account as the key
# Write-Host "Testing a Database with User Account: " -NoNewline
# $expectedPassword = "3ZUVBh2SA4pnmk5R"
# Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithUserAccount.kdbx" -WindowsUserAccount | Assert-Secret

# TEst a database which uses both a key file key and password key
Write-Host "Testing a Database with a Key File and Password: " -NoNewline
$expectedPassword = "trlasJhJlVuZHETS"
Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithKeyFileAndPassword.kdbx" -KeyFile "$PSScriptRoot\DatabaseKeyFile.keyx" -MasterPassword $secureString | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses both a key file key and Windows user account key
# Write-Host "Testing a Database with a Key File and User Account: " -NoNewline
# $expectedPassword = "LgAXW2iIjRAgczfT"
# Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithKeyFileAndUserAccount.kdbx" -KeyFile "$PSScriptRoot\DatabaseKeyFile.keyx" -WindowsUserAccount | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses both a password key and Windows user account key
# Write-Host "Testing a Database with a Password and User Account: " -NoNewline
# $expectedPassword = "Bf9GZ9dM0UBt2F5c"
# Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithPasswordAndUserAccount.kdbx" -MasterPassword $secureString -WindowsUserAccount | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses all three keys
# Write-Host "Testing a Database with a Password User Account and Key File: " -NoNewline
# $expectedPassword = "z3jZ3IhHM8bz2NGt"
# Open-PowerPassDatabase -Path "$PSScriptRoot\DatabaseWithPasswordUserAccountAndKeyFile.kdbx" -KeyFile "$PSScriptRoot\DatabaseKeyFile.keyx" -MasterPassword $secureString -WindowsUserAccount | Assert-Secret

# Test a database with multiple entries with the same Title
Write-Host "Testing a Database with Indentical Entries" -NoNewline
$localDb = Open-PowerPassDatabase -Path "$PSScriptRoot\DbPasswordMultiEntry.kdbx" -MasterPassword $secureString
Get-PowerPassSecret -Database $localDb -Match "Test Entry" | Format-Table

# Test a database with multiple entries using wildcards
Write-Host "Testing a Database to get All Entries" -NoNewline
Get-PowerPassSecret -Database $localDb | Format-Table

# Test a database with multiple entries using Test and wildcards
Write-Host "Testing a Database with Wilcard Search 'Test*'" -NoNewline
Get-PowerPassSecret -Database $localDb -Match "Test*" | Format-Table