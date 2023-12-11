Write-Output "This test script will test the AES implementation of PowerPass"
Write-Output "These tests should pass in both Windows PowerShell and PowerShell 7 on all operating systems"
Write-Output "Testing module import"
Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
} else {
    Write-Output "Verified PowerPass module present"
}
if( (Get-PowerPass).Implementation -ne "AES" ) {
    throw "This test is for the AES implementation of PowerPass, you have the $((Get-PowerPass).Implementation) implementation installed"
} else {
    Write-Output "Verified PowerPass AES implementation present"
}

$answer = Read-Host "WARNING: This test battery will erase ALL your locker secrets. Proceed? [N/y]"
if( $answer ) {
    if( $answer -eq "y" ) {
        Write-Output "Clearing the PowerPass locker"
        Clear-PowerPassLocker -Force
    } else {
        throw "Testing cancelled by user"
    }
} else {
    throw "Testing cancelled by user"
}

Write-Output "Setting up constants and variables"
$lockerExport = Join-Path -Path $PSScriptRoot -ChildPath "powerpass_locker.bin"

Write-Output "Testing Read-PowerPassSecret with empty locker"
$secret = Read-PowerPassSecret | ? Title -eq "Default"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Fail"
}

Write-Output "Testing Write-PowerPassSecret unit test"
Write-PowerPassSecret -Title "Unit Test"

Write-Output "Testing Read function with parameter"
$secret = Read-PowerPassSecret -Match "Unit Test"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Assert failed"
}
$secret = $null
Write-Output "Testing Read function with no parameter name"
$secret = Read-PowerPassSecret "Unit Test"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Assert failed"
}
$secret = $null
Write-Output "Testing Read function from pipeline"
$secret = "Unit Test" | Read-PowerPassSecret
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Assert failed"
}
$secret = $null

Write-Output "Testing Read-PowerPassSecret unit test"
$secret = Read-PowerPassSecret | ? Title -eq "Unit Test"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Output "Testing Clear-PowerPassLocker"
Clear-PowerPassLocker -Force

Write-Output "Testing Read-PowerPassSecret after clear - default"
$secret = Read-PowerPassSecret | ? Title -eq "Default"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Output "Testing Read-PowerPassSecret after clear - unit test"
$secret = Read-PowerPassSecret | ? Title -eq "Unit Test"
if( $secret ) {
    Write-Warning "Fail"
} else {
    Write-Output "Pass"
}
$secret = $null

Write-Output "Testing Export-PowerPassLocker"
if( Test-Path $lockerExport ) {
    Remove-Item $lockerExport -Force
}
Write-PowerPassSecret -Title "Export Test"
Export-PowerPassLocker -Path $PSScriptRoot
if( Test-Path $lockerExport ) {
    Write-Output "Pass"
} else {
    Write-Warning "Fail: no locker file"
}

Write-Output "Testing Import-PowerPassLocker"
Import-PowerPassLocker -LockerFile $lockerExport
$secret = Read-PowerPassSecret | ? Title -eq "Export Test"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Output "Cleaning up for next test"
Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) {
    Remove-Item $lockerExport -Force
}

Write-Output "Testing New-PowerPassRandomPassword"
$randomPassword = New-PowerPassRandomPassword
if( $randomPassword ) {
    Write-Output "Pass"
} else {
    Write-Output "Fail"
}

Write-Output "Testing Update-PowerPassKey"
Write-PowerPassSecret -Title "Update Test"
Update-PowerPassKey
$secret = Read-PowerPassSecret | ? Title -eq "Update Test"
if( $secret ) {
    Write-Output "Pass"
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Output "Testing Remove-PowerPassSecret"
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
            Write-Output "Pass"
        } else {
            Write-Warning "Fail"
        }
    }
} else {
    Write-Warning "Fail"
}
$secret = $null

Write-Output "Cleanup"
Clear-PowerPassLocker -Force
if( Test-Path $lockerExport ) {
    Remove-Item $lockerExport -Force
}