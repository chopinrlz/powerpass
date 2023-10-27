<#
    Test script for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# First test is loading the PowerPass module
Write-Host "Testing module import"
Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Assert-SecretCollection
# ------------------------------------------------------------------------------------------------------------- #

function Assert-SecretCollection {
    <#
        .SYNOPSIS
        Compares an array of secrets to an array of titles for said secrets in associative order.
        .DESCRIPTION
        To assert that a search returns the expected results from Get-PowerPassSecret we check the
        collection of results returned, sorted in alphabetical order by Title, to the string array
        of Titles (also sorted) for results we expect based on the test case. The Title of the first
        search result in $Collection is compared to the first string in $Titles and so forth and
        so on until the end of the $Titles array is reached.
        .PARAMETER Collection
        The collection returned from Get-PowerPassSecret sorted by Title.
        .PARAMETER Titles
        A string array of Titles sorted in alphabetical order to search for in Collection.
        .OUTPUTS
        This function does not output anything, but it writes the result of the assertion to the host.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object[]]
        $Collection,
        [Parameter(Mandatory = $true)]
        [string[]]
        $Titles
    )
    $assert = $true
    $indexer = 0
    $Titles | ForEach-Object {
        $assert = $assert -and ( ($Collection[$indexer]).Title -eq $_ )
        $indexer++
    }
    if ( $assert ) {
        Write-Host "Assert passed"
    } else {
        Write-Warning "Assert failed"
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Assert-Strings
# ------------------------------------------------------------------------------------------------------------- #

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

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Assert-Secret
# ------------------------------------------------------------------------------------------------------------- #

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

# Notify
Write-Host "Defining test constants"

# Key file for all test cases
$keyFilePath = "$PSScriptRoot\keepass-keyfile.keyx"

# Master password for all test cases
$secureString = ConvertTo-SecureString -String "12345" -AsPlainText -Force

# Test a database which uses a password key
Write-Host "Testing a Database with a Password: " -NoNewline
$script:expectedPassword = "BkLQzZvxEV5Znav7"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pw.kdbx" -MasterPassword $secureString | Assert-Secret

# Test a database which uses a key file key
Write-Host "Testing a Database with a Key File: " -NoNewline
$script:expectedPassword = "C4uqg38rjAdoo1AT"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-key.kdbx" -KeyFile $keyFilePath | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses the Windows user account as the key
# Write-Host "Testing a Database with User Account: " -NoNewline
# $expectedPassword = "AAhvNSLcjLEaSfa6"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-user.kdbx" -WindowsUserAccount | Assert-Secret

# Test a database which uses both a key file key and password key
Write-Host "Testing a Database with a Key File and Password: " -NoNewline
$expectedPassword = "trlasJhJlVuZHETS"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-keypw.kdbx" -KeyFile $keyFilePath -MasterPassword $secureString | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses both a key file key and Windows user account key
# Write-Host "Testing a Database with a Key File and User Account: " -NoNewline
# $expectedPassword = "LgAXW2iIjRAgczfT"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-keyuser.kdbx" -KeyFile $keyFilePath -WindowsUserAccount | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses both a password key and Windows user account key
# Write-Host "Testing a Database with a Password and User Account: " -NoNewline
# $expectedPassword = "Bf9GZ9dM0UBt2F5c"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwuser.kdbx" -MasterPassword $secureString -WindowsUserAccount | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses all three keys
# Write-Host "Testing a Database with a Password User Account and Key File: " -NoNewline
# $expectedPassword = "z3jZ3IhHM8bz2NGt"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwkeyuser.kdbx" -KeyFile $keyFilePath -MasterPassword $secureString -WindowsUserAccount | Assert-Secret

# Test a database with multiple entries with the same Title
Write-Host "Testing a Database with Indentical Entries: " -NoNewline
$expectedResults = @('Test Entry','Test Entry','Test Entry')
$localDb = Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwmulti.kdbx" -MasterPassword $secureString
$actualResults = Get-PowerPassSecret -Database $localDb -Match "Test Entry"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults

# Test a database with multiple entries using wildcards
Write-Host "Testing a Database to get All Entries: " -NoNewline
$expectedResults = @('Other Words in Title','Test Entry','Test Entry','Test Entry','Test User')
$actualResults = Get-PowerPassSecret -Database $localDb | Sort-Object -Property "Title"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults

# Test a database with multiple entries using Test and wildcards
Write-Host "Testing a Database with Wilcard Search 'Test*': " -NoNewline
$expectedResults = @('Test Entry','Test Entry','Test Entry','Test User')
$actualResults = Get-PowerPassSecret -Database $localDb -Match "Test*" | Sort-Object -Property "Title"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults

# Clear the Locker to Unit Test the Locker
Write-Host "Creating a new Locker"
Clear-PowerPassLocker

# Read the Default Secret from a New Locker
Write-Host "Testing the Default Secret in a new Locker: " -NoNewline
$default = Read-PowerPassSecret
if( $default.Title -eq "Default" ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}

# Write a New Secret into the Locker
Write-Host "Testing Write function to Locker"
Write-PowerPassSecret -Title "Unit Testing" -UserName "unit test user" -Password "unit test password" -URL "https://github.com/chopinrlz/powerpass" -Notes "Unit testing." -Expires (Get-Date)

# Read out the new Secret
Write-Host "Testing reading the new Secret: " -NoNewline
$unitTesting = Read-PowerPassSecret -Match "Unit Testing"
if( $unitTesting.Title -eq "Unit Testing" ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}