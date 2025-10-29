<#
    Test script for the AES flavor of PowerPass
    Copyright 2023-2025 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

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

# Import the module

"Importing the module"

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

"Setting up constants"

$lockerExport = Join-Path -Path $PSScriptRoot -ChildPath "powerpass_locker.bin"

# Test - reading secrets from an empty locker

"Reading secrets from an empty locker"

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

"Write a secret and read it back"

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

"Write a secret with a masked password and read it back"

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

"Read secret with pipeline input"

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

"Read secret with pipeline filter"

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

"Clear out the locker to setup for the next tests"

Clear-PowerPassLocker -Force

# Test - double check clear works and read results in Default secret

"Double check locker clear works"

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

"Make sure the unit test secret has been cleared"

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

"Load locker with test secrets via pipeline"

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
                Write-Warning "Test failed: generator secret value mismatch on read"
            }
        }
    }
}

# Test - load the locker with secrets from a CSV file

"Load locker with secrets from a CSV file"

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

"Export locker"

if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }
Write-PowerPassSecret -Title "Export Test"
Write-PowerPassSecret -Title "Merge Secret" -UserName "older@gmail.com"
Write-PowerPassSecret -Title "Newer Secret" -UserName "newer@gmail.com"
Export-PowerPassLocker -Path $PSScriptRoot
if( -not (Test-Path $lockerExport) ) {
    Write-Warning "Test failed: export file not created"
}

# Test - import locker

"Import locker"

Import-PowerPassLocker -LockerFile $lockerExport
$secret = Read-PowerPassSecret -Title "Export Test"
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

# Test - merge import locker

"Import locker with merge"

Clear-PowerPassLocker -Force
Write-PowerPassSecret -Title "Merge Secret" -UserName "newer@gmail.com"
Write-PowerPassSecret -Title "Local Secret"
Import-PowerPassLocker -LockerFile $lockerExport -Merge
$local = Read-PowerPassSecret -Title "Local Secret"
$secret = Read-PowerPassSecret -Title "Export Test"
if( -not $local ) {
    Write-Warning "Test failed: local secret missing from locker"
}
if( -not $secret ) {
    Write-Warning "Test failed: imported secret missing from locker"
}
$mergeSecret = Read-PowerPassSecret -Title "Merge Secret"
$mergeSecretCount = (Measure-Object -InputObject $mergeSecret).Count
if( $mergeSecretCount -ne 1 ) {
    Write-Warning "Test failed: there should only be 1 Merge Secret after merge"
} else {
    if( $mergeSecret.UserName -ne "older@gmail.com" ) {
        Write-Warning "Test failed: older secret UserName not updated during merge"
    }
}
$secret = $null
$secretCount = -1

# Test - merge import by date

"Merge import by date"

Clear-PowerPassLocker -Force
Write-PowerPassSecret -Title "Merge Secret" -UserName "newer@gmail.com"
Import-PowerPassLocker -LockerFile $lockerExport -Merge -ByDate
$mergeSecret = Read-PowerPassSecret -Title "Merge Secret"
if( -not $mergeSecret ) {
    Write-Warning "Test failed: older secret missing after import"
} else {
    if( $mergeSecret.UserName -ne "newer@gmail.com" ) {
        Write-Warning "Test failed: newer secret updated by older secret"
    }
}
$secret = $null
$secretCount = -1

# Clean up for the next test by clearing the locker and the export file

"Clean up for the next test"

Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }

# Test - key rotation

"Key rotation"

Write-PowerPassSecret -Title "Key Rotation"
Update-PowerPassKey
$secret = Read-PowerPassSecret | ? Title -eq "Key Rotation"
$secretCount = (Measure-Object -InputObject $secret).Count
if( -not $secret ) {
    Write-Warning "Test failed: key rotation secret missing"
} else {
    if( $secretCount -eq 1 ) {
        if( -not ($secret.Title -eq "Key Rotation") ) {
            Write-Warning "Test failed: Key Rotation secret Title invalid"
        }
    } else {
        Write-Warning "Test failed: multiple key rotation secrets returned"
    }
}
$secret = $null
$secretCount = -1

# Test - removing secrets

"Removing secrets"

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

# Test - custom file settings

"Custom file paths"

Clear-PowerPassLocker -Force
Set-PowerPass -Reset
Clear-PowerPassLocker -Force
Write-PowerPassSecret -Title "Local Secret"
Set-PowerPass -NewLockerFolderPath $PSScriptRoot -NewLockerKeyFolderPath $PSScriptRoot
$remote = Get-PowerPass
if( $remote.LockerFolderPath -ne $PSScriptRoot ) {
    Write-Warning "Test failed: first locker folder path incorrect"
}
if( $remote.LockerFilePath -ne (Join-Path -Path $PSScriptRoot -ChildPath ".powerpass_locker") ) {
    Write-Warning "Test failed: first locker file path incorrect"
}
if( $remote.LockerKeyFolderPath -ne $PSScriptRoot ) {
    Write-Warning "Test failed: first locker key folder path incorrect"
}
if( $remote.LockerKeyFilePath -ne (Join-Path -Path $PSScriptRoot -ChildPath ".locker_key") ) {
    Write-Warning "Test failed: first locker key file path incorrect"
}
Set-PowerPass -NewLockerFolderPath $PSScriptRoot -NewLockerFileName ".remote_locker" -NewLockerKeyFolderPath $PSScriptRoot -NewLockerKeyFileName ".remote_locker_key"
$remote = Get-PowerPass
if( $remote.LockerFolderPath -ne $PSScriptRoot ) {
    Write-Warning "Test failed: second locker folder path incorrect"
}
if( $remote.LockerFilePath -ne (Join-Path -Path $PSScriptRoot -ChildPath ".remote_locker") ) {
    Write-Warning "Test failed: second locker file path incorrect"
}
if( $remote.LockerKeyFolderPath -ne $PSScriptRoot ) {
    Write-Warning "Test failed: second locker key folder path incorrect"
}
if( $remote.LockerKeyFilePath -ne (Join-Path -Path $PSScriptRoot -ChildPath ".remote_locker_key") ) {
    Write-Warning "Test failed: second locker key file path incorrect"
}
Write-PowerPassSecret -Title "Remote Secret"
$remote = Read-PowerPassSecret -Title "Remote Secret"
if( -not $remote ) {
    Write-Warning "Test failed: remote secret not returned from remote locker"
}
Set-PowerPass -Reset
$local = Read-PowerPassSecret -Title "Local Secret"
if( -not $local ) {
    Write-Warning "Test failed: local secret not returned from local locker"
}
Set-PowerPass -NewLockerFolderPath $PSScriptRoot -NewLockerFileName ".remote_locker" -NewLockerKeyFolderPath $PSScriptRoot -NewLockerKeyFileName ".remote_locker_key"
$temp = Get-PowerPass
Clear-PowerPassLocker -Force
if( Test-Path $temp.LockerFilePath ) {
    Write-Warning "Test failed: locker clear failed with custom file path settings"
}
if( Test-Path $temp.LockerKeyFilePath ) {
    Write-Warning "Test failed: key clear failed with custom file path settings"
}

# Test - performance

"Performance"

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

"Final clean up"

Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) { Remove-Item $lockerExport -Force }