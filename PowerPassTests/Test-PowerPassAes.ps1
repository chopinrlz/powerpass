Write-Host "This test script will test the AES implementation of PowerPass"
Write-Host "These tests should pass in both Windows PowerShell and PowerShell 7 on all operating systems"
Write-Host "Testing module import"
Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
} else {
    Write-Host "Verified PowerPass module present"
}
if( (Get-PowerPass).Implementation -ne "AES" ) {
    throw "This test is for the AES implementation of PowerPass, you have the $((Get-PowerPass).Implementation) implementation installed"
} else {
    Write-Host "Verified PowerPass AES implementation present"
}

$answer = Read-Host "WARNING: This test battery will erase ALL your locker secrets. Proceed? [N/y]"
if( $answer ) {
    if( $answer -eq "y" ) {
        Write-Host "Clearing the PowerPass locker"
        Clear-PowerPassLocker -Force
    } else {
        throw "Testing cancelled by user"
    }
} else {
    throw "Testing cancelled by user"
}

Write-Host "Testing Read-PowerPassSecret with empty locker: " -NoNewline
$secret = Read-PowerPassSecret | ? Title -eq "Default"
if( $secret ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail"
}

Write-Host "Testing Write-PowerPassSecret unit test"
Write-PowerPassSecret -Title "Unit Test"

Write-Host "Testing Read function with parameter: " -NoNewline
$secret = Read-PowerPassSecret -Match "Unit Test"
if( $secret ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}
$secret = $null
Write-Host "Testing Read function with no parameter name: " -NoNewline
$secret = Read-PowerPassSecret "Unit Test"
if( $secret ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}
$secret = $null
Write-Host "Testing Read function from pipeline: " -NoNewline
$secret = "Unit Test" | Read-PowerPassSecret
if( $secret ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}
$secret = $null

Write-Host "Testing Read-PowerPassSecret unit test: " -NoNewline
$secret = Read-PowerPassSecret | ? Title -eq "Unit Test"
if( $secret ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Host "Testing Clear-PowerPassLocker"
Clear-PowerPassLocker -Force

Write-Host "Testing Read-PowerPassSecret after clear - default: " -NoNewline
$secret = Read-PowerPassSecret | ? Title -eq "Default"
if( $secret ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Host "Testing Read-PowerPassSecret after clear - unit test: " -NoNewline
$secret = Read-PowerPassSecret | ? Title -eq "Unit Test"
if( $secret ) {
    Write-Warning "Fail"
} else {
    Write-Host "Pass"
}
$secret = $null

Write-Host "Testing Export-PowerPassLocker: " -NoNewline
$lockerExport = "$PSScriptRoot\powerpass_locker.bin"
if( Test-Path $lockerExport ) {
    Remove-Item $lockerExport -Force
}
Write-PowerPassSecret -Title "Export Test"
Export-PowerPassLocker -Path $PSScriptRoot -Password "12345"
if( Test-Path $lockerExport ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail: no locker file"
}

Write-Host "Testing Import-PowerPassLocker: " -NoNewline
Import-PowerPassLocker -LockerFile "$PSScriptRoot\powerpass_locker.bin" -Password "12345" -Force
$secret = Read-PowerPassSecret | ? Title -eq "Export Test"
if( $secret ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Host "Cleaning up for next test"
Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) {
    Remove-Item $lockerExport -Force
}

Write-Host "Testing Export-PowerPassLocker with strong password: " -NoNewline
Write-PowerPassSecret -Title "Export Test"
Export-PowerPassLocker -Path $PSScriptRoot -Password "h76fnJ&fd543JMnd4#d9*mnc2@1k;:5r"
if( Test-Path $lockerExport ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail: no locker file"
}

Write-Host "Testing Import-PowerPassLocker with strong password: " -NoNewline
Import-PowerPassLocker -LockerFile "$PSScriptRoot\powerpass_locker.bin" -Password "h76fnJ&fd543JMnd4#d9*mnc2@1k;:5r" -Force
$secret = Read-PowerPassSecret | ? Title -eq "Export Test"
if( $secret ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Host "Testing New-PowerPassRandomPassword: " -NoNewline
$randomPassword = New-PowerPassRandomPassword
if( $randomPassword ) {
    Write-Host "Pass"
} else {
    Write-Host "Fail"
}

Write-Host "Testing Update-PowerPassKey: " -NoNewline
Write-PowerPassSecret -Title "Update Test"
Update-PowerPassKey
$secret = Read-PowerPassSecret | ? Title -eq "Update Test"
if( $secret ) {
    Write-Host "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Host "Testing Remove-PowerPassSecret: " -NoNewline
Write-PowerPassSecret -Title "Delete Me"
Write-PowerPassSecret -Title "Keep Me"
$secret = Read-PowerPassSecret -Match "Delete Me"
if( $secret ) {
    Remove-PowerPassSecret -Title "Delete Me"
    $secret = Read-PowerPassSecret -Match "Delete Me"
    if( $secret ) {
        Write-Warning "Fail"
    } else {
        $secret = Read-PowerPassSecret -Match "Keep Me"
        if( $secret ) {
            Write-Host "Pass"
        } else {
            Write-Warning "Fail"
        }
    }
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Host "Cleanup"
Clear-PowerPassLocker -Force
Remove-Item -Path "$PSScriptRoot\powerpass_locker.bin" -Force