<#
    Test script for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Make sure we're in the right run-time
if( $PSVersionTable.PSVersion.Major -ne 5 ) {
    throw "This test script is for the DP API implementation in Windows PowerShell 5"
} else {
    Write-Output "Verified Windows PowerShell 5 shell"
}

# First test is loading the PowerPass module
Write-Output "Testing module import"
Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
} else {
    Write-Output "Verified module import"
}
if( (Get-PowerPass).Implementation -ne "DPAPI" ) {
    throw "This test is for the DPAPI implementation of PowerPass, you have the $((Get-PowerPass).Implementation) implementation installed"
} else {
    Write-Output "Verified DP API implementation present"
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
        Write-Output "Assert passed"
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
        Write-Output "Assert passed"
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
Write-Output "Defining test constants"

# Key file for all test cases
$keyFilePath = "$PSScriptRoot\keepass-keyfile.keyx"

# Master password for all test cases
$secureString = ConvertTo-SecureString -String "12345" -AsPlainText -Force

# Test a database which uses a password key
Write-Output "Testing a Database with a Password"
$script:expectedPassword = "BkLQzZvxEV5Znav7"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pw.kdbx" -MasterPassword $secureString | Assert-Secret

# Test a database which uses a key file key
Write-Output "Testing a Database with a Key File"
$script:expectedPassword = "C4uqg38rjAdoo1AT"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-key.kdbx" -KeyFile $keyFilePath | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses the Windows user account as the key
# Write-Output "Testing a Database with User Account"
# $expectedPassword = "AAhvNSLcjLEaSfa6"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-user.kdbx" -WindowsUserAccount | Assert-Secret

# Test a database which uses both a key file key and password key
Write-Output "Testing a Database with a Key File and Password"
$expectedPassword = "trlasJhJlVuZHETS"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-keypw.kdbx" -KeyFile $keyFilePath -MasterPassword $secureString | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses both a key file key and Windows user account key
# Write-Output "Testing a Database with a Key File and User Account"
# $expectedPassword = "LgAXW2iIjRAgczfT"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-keyuser.kdbx" -KeyFile $keyFilePath -WindowsUserAccount | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses both a password key and Windows user account key
# Write-Output "Testing a Database with a Password and User Account"
# $expectedPassword = "Bf9GZ9dM0UBt2F5c"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwuser.kdbx" -MasterPassword $secureString -WindowsUserAccount | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses all three keys
# Write-Output "Testing a Database with a Password User Account and Key File"
# $expectedPassword = "z3jZ3IhHM8bz2NGt"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwkeyuser.kdbx" -KeyFile $keyFilePath -MasterPassword $secureString -WindowsUserAccount | Assert-Secret

# Test a database with multiple entries with the same Title
Write-Output "Testing a Database with Indentical Entries"
$expectedResults = @('Test Entry','Test Entry','Test Entry')
$localDb = Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwmulti.kdbx" -MasterPassword $secureString
$actualResults = Get-PowerPassSecret -Database $localDb -Match "Test Entry"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults
$actualResults = $null

# Test a database with multiple entries using wildcards
Write-Output "Testing a Database to get All Entries"
$expectedResults = @('Other Words in Title','Test Entry','Test Entry','Test Entry','Test User')
$actualResults = Get-PowerPassSecret -Database $localDb | Sort-Object -Property "Title"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults
$actualResults = $null

# Test a database with multiple entries using Test and wildcards
Write-Output "Testing a Database with Wilcard Search 'Test*'"
$expectedResults = @('Test Entry','Test Entry','Test Entry','Test User')
$actualResults = Get-PowerPassSecret -Database $localDb -Match "Test*" | Sort-Object -Property "Title"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults
$actualResults = $null

# Clear the Locker to Unit Test the Locker
Write-Output "Testing the Default Secret in a new Locker"
Clear-PowerPassLocker -Force
$default = Read-PowerPassSecret
if( $default.Title -eq "Default" ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}

# Write a New Secret into the Locker
Write-Output "Testing Write function to Locker"
Write-PowerPassSecret -Title "Unit Testing" -UserName "unit test user" -Password "unit test password" -URL "https://github.com/chopinrlz/powerpass" -Notes "Unit testing." -Expires (Get-Date)
$unitTesting = Read-PowerPassSecret -Match "Unit Testing"
if( $unitTesting.Title -eq "Unit Testing" ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}

# Test reading secrets in various ways
Write-Output "Testing Read function with parameter"
$secret = Read-PowerPassSecret -Match "Unit Testing"
if( $secret ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}
$secret = $null
Write-Output "Testing Read function with no parameter name"
$secret = Read-PowerPassSecret "Unit Testing"
if( $secret ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}
$secret = $null
Write-Output "Testing Read function from pipeline"
$secret = "Unit Testing" | Read-PowerPassSecret
if( $secret ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}
$secret = $null

# Test the export functionality
Write-Output "Testing locker export"
Export-PowerPassLocker -Path $PSScriptRoot
if( Test-Path "$PSScriptRoot\powerpass_locker.bin" ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}

# Test the clear functionality, interactively
$unitTesting = $null
$default = $null
Write-Output "Testing locker clear (interactive, no force)"
Clear-PowerPassLocker
$unitTesting = Read-PowerPassSecret -Match "Unit Testing"
$default = Read-PowerPassSecret -Match "Default"
if( $unitTesting ) {
    Write-Warning "Assert failed"
} else {
    if( $default.Title -eq "Default" ) {
        Write-Output "Assert passed"
    } else {
        Write-Warning "Assert failed"
    }
}

# Test the clear functionality, with force
$default = $null
Write-Output "Testing locker clear (force)"
Clear-PowerPassLocker -Force
$default = Read-PowerPassSecret
if( $default.Title -eq "Default" ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}

# Test the import functionality
$unitTesting = $null
Write-Output "Testing locker import"
Clear-PowerPassLocker -Force
Import-PowerPassLocker -LockerFilePath "$PSScriptRoot\powerpass_locker.bin"
$unitTesting = Read-PowerPassSecret -Match "Unit Testing"
if( $unitTesting.Title -eq "Unit Testing" ) {
    Write-Output "Assert passed"
} else {
    Write-Warning "Assert failed"
}

# Test removing secrets
$secret = $null
Write-Output "Testing secret removal"
Write-PowerPassSecret -Title "Delete Me"
Write-PowerPassSecret -Title "Keep Me"
$secret = Read-PowerPassSecret -Match "Delete Me"
if( $secret ) {
    Remove-PowerPassSecret -Title "Delete Me"
    $secret = Read-PowerPassSecret -Match "Delete Me"
    if( $secret ) {
        Write-Warning "Assert failed"
    } else {
        $secret = Read-PowerPassSecret -Match "Keep Me"
        if( $secret ) {
            Write-Output "Assert passed"
        } else {
            Write-Warning "Assert failed"
        }
    }
} else {
    Write-Warning "Assert failed"
}

# Clean up
Write-Output "Cleaning up"
Remove-Item "$PSScriptRoot\powerpass_locker.bin" -Force