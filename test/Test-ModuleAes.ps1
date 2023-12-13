<#
    Test script for the AES flavor of PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

function Test-Mismatch {
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
    $expCheck = ($Left.Expires -ne $Right.Expires)
    $createCheck = ($Left.Created -ne $Right.Created)
    $modCheck = ($Left.Modified -ne $Right.Modified)
    Write-Output ($titleCheck -or $pwCheck -or $urlCheck -or $notesCheck -or $expCheck -or $createCheck -or $modCheck )
}

# Import the module

Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}
if( (Get-PowerPass).Implementation -ne "AES" ) {
    throw "This test is for the AES implementation of PowerPass, you have the $((Get-PowerPass).Implementation) implementation installed"
}

# Issue warning to user

$answer = Read-Host "WARNING: This test battery will erase ALL your locker secrets. Proceed? [N/y]"
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
        Expires = Get-Date
    }
}
$tempSecrets | Write-PowerPassSecret
$readSecrets = Read-PowerPassSecret -Match "generator secret*" -PlainTextPasswords
Write-Output "Emitting read secrets to output"
Write-Output $readSecrets
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
if( -not $secret ) {
    Write-Warning "Test failed: export test not present after import"
} else {
    if( $secret.Length -eq 1 ) {
        if( -not ($secret.Title -eq "Export Test") ) {
            Write-Warning "Test failed: export test secret title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple export test secrets returned after import"
    }
}
$secret = $null

# Clean up for the next test by clearing the locker and the export file

Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }

# Test - key rotation

Write-PowerPassSecret -Title "Key Rotation"
Update-PowerPassKey
$secret = Read-PowerPassSecret | ? Title -eq "Key Rotation"
if( -not $secret ) {
    Write-Warning "Test failed: key rotation secret missing"
} else {
    if( $secret.Length -eq 1 ) {
        if( -not ($secret.Title -eq "Key Rotation") ) {
            Write-Warning "Test failed: Key Rotation secret Title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple key rotation secrets returned"
    }
}
$secret = $null

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

# Clean up everything

Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }