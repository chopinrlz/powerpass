<#
    Test script for the Data Protection API flavor of PowerPass
    Copyright 2023-2024 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Verify run-time

if( $PSVersionTable.PSVersion.Major -ne 5 ) {
    throw "This test script is for the DP API implementation in Windows PowerShell 5"
}

# Load the module

Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}

# Verify module implementation

if( (Get-PowerPass).Implementation -ne "DPAPI" ) {
    throw "This test is for the DPAPI implementation of PowerPass, you have the $((Get-PowerPass).Implementation) implementation installed"
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Test-Mismatch
# ------------------------------------------------------------------------------------------------------------- #

function Test-Mismatch {
    <#
        .SYNOPSIS
        Compares one secret with another to confirm they are identical. Does not check dates because DateTime
        objects are not identical to their .NET counterparts after they are serialized to JSON.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Left,
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Right
    )
    $titleCheck = ($Left.Title -ne $Right.Title)
    $pwCheck = ($Left.Password -ne $Right.Password)
    $urlCheck = ($Left.URL -ne $Right.URL)
    $notesCheck = ($Left.Notes -ne $Right.Notes)
    Write-Output ($titleCheck -or $pwCheck -or $urlCheck -or $notesCheck)
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
    if( -not $assert ) {
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
    if( -not ([String]::Equals( $StringA, $StringB, "Ordinal" )) ) {
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

# Key file for all test cases
$keyFilePath = "$PSScriptRoot\keepass-keyfile.keyx"

# Master password for all test cases
$secureString = ConvertTo-SecureString -String "12345" -AsPlainText -Force

# Test a database which uses a password key
Write-Output "Testing a KeePass 2 database with a Password"
$script:expectedPassword = "BkLQzZvxEV5Znav7"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pw.kdbx" -MasterPassword $secureString | Assert-Secret

# Test a database which uses a key file key
Write-Output "Testing a KeePass 2 database with a Key File"
$script:expectedPassword = "C4uqg38rjAdoo1AT"
Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-key.kdbx" -KeyFile $keyFilePath | Assert-Secret

# Cannot be done for anyone else but yourself
# Test a database which uses the Windows user account as the key
# Write-Output "Testing a Database with User Account"
# $expectedPassword = "AAhvNSLcjLEaSfa6"
# Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-user.kdbx" -WindowsUserAccount | Assert-Secret

# Test a database which uses both a key file key and password key
Write-Output "Testing a KeePass 2 database with a Key File and Password"
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
Write-Output "Testing a KeePass 2 database with Indentical Entries"
$expectedResults = @('Test Entry','Test Entry','Test Entry')
$localDb = Open-PowerPassDatabase -Path "$PSScriptRoot\kpdb-pwmulti.kdbx" -MasterPassword $secureString
$actualResults = Get-PowerPassSecret -Database $localDb -Match "Test Entry"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults
$actualResults = $null

# Test a database with multiple entries using wildcards
Write-Output "Testing a KeePass 2 database to get All Entries"
$expectedResults = @('Other Words in Title','Test Entry','Test Entry','Test Entry','Test User')
$actualResults = Get-PowerPassSecret -Database $localDb | Sort-Object -Property "Title"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults
$actualResults = $null

# Test a database with multiple entries using Test and wildcards
Write-Output "Testing a KeePass 2 database with Wilcard Search 'Test*'"
$expectedResults = @('Test Entry','Test Entry','Test Entry','Test User')
$actualResults = Get-PowerPassSecret -Database $localDb -Match "Test*" | Sort-Object -Property "Title"
Assert-SecretCollection -Collection $actualResults -Titles $expectedResults
$actualResults = $null

# Issue warning to user

$answer = Read-Host "WARNING: The remaining test cases will erase your Locker secrets. Proceed? [N/y]"
if( $answer ) {
    if( $answer -eq "y" ) {
        Clear-PowerPassLocker -Force
    } else {
        throw "Testing cancelled by user"
    }
} else {
    throw "Testing cancelled by user"
}

# Setup constants for testing

$lockerExport = Join-Path -Path $PSScriptRoot -ChildPath "powerpass_locker.bin"

# Test - reading secrets from an empty locker

$secret = Read-PowerPassSecret | ? Title -eq "Default"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: reading secrets from empty locker"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Default") ) {
            Write-Warning "Test failed: Default secret Title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - write a secret and read it back

Write-PowerPassSecret -Title "Unit Test"
$secret = Read-PowerPassSecret -Match "Unit Test"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: unit test secret not returned"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Unit Test") ) {
            Write-Warning "Test failed: unit test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - write a secret with a masked password and read it back

Write-PowerPassSecret -Title "Masking Test" -MaskPassword
$secret = Read-PowerPassSecret -Match "Masking Test"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: masking test secret not returned"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Masking Test") ) {
            Write-Warning "Test failed: masking test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple masking test secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - read secret with pipeline input

$secret = "Unit Test" | Read-PowerPassSecret
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: unit test secret not returned"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Unit Test") ) {
            Write-Warning "Test failed: unit test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - read secret with pipeline filter

$secret = Read-PowerPassSecret | ? Title -eq "Unit Test"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: unit test secret not returned"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Unit Test") ) {
            Write-Warning "Test failed: unit test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Clear out the locker to setup for the next tests

Clear-PowerPassLocker -Force

# Test - double check clear works and read results in Default secret

$secret = Read-PowerPassSecret | ? Title -eq "Default"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: unit test secret not returned"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Default") ) {
            Write-Warning "Test failed: unit test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - make sure the unit test secret has been cleared

$secret = Read-PowerPassSecret | ? Title -eq "Unit Test"
if( $secret ) {
    Write-Warning "Test failed: unit test secret not cleared"
}
$secret = $null
$secret = Read-PowerPassSecret -Title "Unit Test"
if( $secret ) {
    Write-Warning "Test failed: cleared unit test secret found with Title search"
}
$secret = $null
$secret = Read-PowerPassSecret -Match "Unit Test"
if( $secret ) {
    Write-Warning "Test failed: cleared unit test secret found with Match search"
}
$secret = $null

# Test - load locker with various test secrets via pipeline

$numTempSecrets = 24
$tempSecrets = 1..$numTempSecrets | % {
    [PSCustomObject]@{
        Title = "generator secret $_"
        UserName = [System.Guid]::NewGuid().ToString()
        Password = New-PowerPassRandomPassword
        URL = "https://github.com/chopinrlz/powerpass"
        Notes = "Generated during testing"
        Expires = (Get-Date).ToUniversalTime()
    }
}
$tempSecrets | Write-PowerPassSecret
$readSecrets = Read-PowerPassSecret -Match "generator secret*" -PlainTextPasswords
if( -not $readSecrets ) {
    Write-Warning "Test failed: generator secrets not read back from locker"
} else {
    if( $readSecrets.Length -ne $numTempSecrets ) {
        Write-Warning "Test failed: should be $numTempSecrets generator secrets, actual is $($readSecrets.Length)"
    } else {
        for( $i = 0; $i -lt $numTempSecrets; $i++ ) {
            $ts = $tempSecrets[$i]
            $rs = $readSecrets[$i]
            $fail = Test-Mismatch -Left $ts -Right $rs
            if( $fail ) {
                Write-Warning "Test failed: secret value mismatch on read"
            }
        }
    }
}

# Test - load the locker with secrets from a CSV file

$csvFilePath = Join-Path -Path $PSScriptRoot -ChildPath "test-secrets.csv"
$csvSecrets = Import-Csv $csvFilePath
$csvSecrets | Write-PowerPassSecret
$readSecrets = Read-PowerPassSecret -Match "Csv*" -PlainTextPasswords
if( -not $readSecrets ) {
    Write-Warning "Test failed: CSV secrets not read back from locker"
} else {
    if( $readSecrets.Length -ne 37 ) {
        Write-Warning "Test failed: should be 37 CSV secrets, actual is $($readSecrets.Length)"
    } else {
        for( $i = 0; $i -lt 37; $i++ ) {
            $ts = $csvSecrets[$i]
            $rs = $readSecrets[$i]
            $fail = Test-Mismatch -Left $ts -Right $rs
            if( $fail ) {
                Write-Warning "Test failed: CSV secret value mismatch on read"
            }
        }
    }
}

# Test - export locker

if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }
Write-PowerPassSecret -Title "Export Test"
Export-PowerPassLocker -Path $PSScriptRoot
if( -not (Test-Path $lockerExport) ) {
    Write-Warning "Test failed: export file not created"
}

# Test - import locker

Import-PowerPassLocker -LockerFile $lockerExport
$secret = Read-PowerPassSecret | ? Title -eq "Export Test"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: export test not present after import"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Export Test") ) {
            Write-Warning "Test failed: export test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple export test secrets returned after import"
    }
}
$secret = $null
$secretCount = -1

# Clean up for the next test by clearing the locker and the export file

Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }

# Test - salt rotation

Write-PowerPassSecret -Title "Salt Rotation"
Update-PowerPassSalt
$secret = Read-PowerPassSecret | ? Title -eq "Salt Rotation"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: salt rotation secret missing"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Salt Rotation") ) {
            Write-Warning "Test failed: Key Rotation secret Title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple key rotation secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - removing secrets

Write-PowerPassSecret -Title "Delete Me"
Write-PowerPassSecret -Title "Keep Me"
$secret = Read-PowerPassSecret -Match "Delete Me"
if( $secret ) {
    Remove-PowerPassSecret -Title "Delete Me"
    $secret = Read-PowerPassSecret -Match "Delete Me"
    if( $secret ) {
        Write-Warning "Test failed: delete me secret not deleted"
    } else {
        $secret = Read-PowerPassSecret -Match "Keep Me"
        if( -not $secret ) {
            Write-Warning "Test failed: keep me secret not retained"
        }
    }
} else {
    Write-Warning "Test failed: delete me secret should appear before test"
}
$secret = $null

# Test - performance

$start = Get-Date
$numTempSecrets = 100
$tempSecrets = 1..$numTempSecrets | % {
    [PSCustomObject]@{
        Title = "generator secret $_"
        UserName = [System.Guid]::NewGuid().ToString()
        Password = New-PowerPassRandomPassword
        URL = "https://github.com/chopinrlz/powerpass"
        Notes = "Generated during testing"
        Expires = (Get-Date).ToUniversalTime()
    }
}
$tempSecrets | Write-PowerPassSecret
$stop = Get-Date
$duration = ($stop - $start).TotalMilliseconds
$pace = ($numTempSecrets / ($duration / 1000)).ToString("0.00")
Write-Output "Performance test (batch writes): $pace secrets per second"
Clear-PowerPassLocker -Force
$start = Get-Date
foreach( $secret in $tempSecrets ) {
    Write-PowerPassSecret -Title $secret.Title -UserName $secret.UserName -Password $secret.Password -URL $secret.URL -Notes $secret.Notes -Expires $secret.Expires
}
$stop = Get-Date
$duration = ($stop - $start).TotalSeconds
$pace = ($numTempSecrets / $duration).ToString("0.00")
Write-Output "Performance test (single writes): $pace secrets per second"

# Clean up everything

Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }