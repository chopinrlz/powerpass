<#
    Test script for Attachments of PowerPass Lockers
    Copyright 2023-2025 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

Import-Module PowerPass
$module = Get-Module | ? Name -eq "PowerPass"
if( -not $module ) {
    throw "Failed to load PowerPass module, did you deploy it?"
}

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

# Test attachment support - text

Write-Output "Testing attachment from text"
$testFile = "hello_world.txt"
$testText = "Hello, world!"
Write-PowerPassAttachment -FileName $testFile -Text $testText
$actualText = Read-PowerPassAttachment -FileName $testFile -AsText
if( $actualText -ne $testText ) {
    Write-Warning "Test failed: Attachment text not identical"
    Write-Output "actualText: $actualText"
}

Write-Output "Testing attachment update from text"
$testText = "Hello, world! (again)"
Write-PowerPassAttachment -FileName $testFile -Text $testText
$actualText = Read-PowerPassAttachment -FileName $testFile -AsText
if( $actualText -ne $testText ) {
    Write-Warning "Test failed: Attachment not updated"
    Write-Output "actualText: $actualText"
}

# Test attachment support - path with byte array assert

Write-Output "Testing attachment create from file path"
$testData = "Hello, file!"
$testFileName = "hello_file.txt"
$testFile = Join-Path -Path $PSScriptRoot -ChildPath $testFileName
if( Test-Path $testFile ) { Remove-Item $testFile -Force }
$testData | Out-File -FilePath $testFile
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes( $testFile )
Write-PowerPassAttachment -FileName $testFileName -Path $testFile
$readBytes = Read-PowerPassAttachment -FileName $testFileName
if( $fileBytes.Length -ne $readBytes.Length ) {
    Write-Warning "Test failed: byte array length mismatch"
} else {
    $match = $true
    for( $i = 0; $i -lt $fileBytes.Length; $i++ ) {
        $match = $match -and ( $fileBytes[$i] -eq $readBytes[$i] )
    }
    if( -not $match ) {
        Write-Warning "Test failed: byte array contents not identical"
    }
}
if( Test-Path $testFile ) { Remove-Item $testFile -Force }

# Test attachment support - path with byte array assert with GZip enabled

Write-Output "Testing attachment create from file path with GZip enabled"
$testData = "Hello, compressed file!"
$testFileName = "hello_file_gzip.txt"
$testFile = Join-Path -Path $PSScriptRoot -ChildPath $testFileName
if( Test-Path $testFile ) { Remove-Item $testFile -Force }
$testData | Out-File -FilePath $testFile
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes( $testFile )
Write-PowerPassAttachment -FileName $testFileName -Path $testFile -GZip
$readBytes = Read-PowerPassAttachment -FileName $testFileName
if( $fileBytes.Length -ne $readBytes.Length ) {
    Write-Warning "Test failed: byte array length mismatch"
} else {
    $match = $true
    for( $i = 0; $i -lt $fileBytes.Length; $i++ ) {
        $match = $match -and ( $fileBytes[$i] -eq $readBytes[$i] )
    }
    if( -not $match ) {
        Write-Warning "Test failed: byte array contents not identical"
    }
}
if( Test-Path $testFile ) { Remove-Item $testFile -Force }

# Test attachment support - literal path

Write-Output "Testing attachment create from file literal path"
$testData = "Hello, literal file!"
$testFileName = "hello_literal_file.txt"
$testFile = Join-Path -Path $PSScriptRoot -ChildPath $testFileName
if( Test-Path $testFile ) { Remove-Item $testFile -Force }
$testData | Out-File -FilePath $testFile
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes( $testFile )
Write-PowerPassAttachment -FileName $testFileName -LiteralPath $testFile
$readBytes = Read-PowerPassAttachment -FileName $testFileName
if( $fileBytes.Length -ne $readBytes.Length ) {
    Write-Warning "Test failed: byte array length mismatch"
} else {
    $match = $true
    for( $i = 0; $i -lt $fileBytes.Length; $i++ ) {
        $match = $match -and ( $fileBytes[$i] -eq $readBytes[$i] )
    }
    if( -not $match ) {
        Write-Warning "Test failed: byte array contents not identical"
    }
}
if( Test-Path $testFile ) { Remove-Item $testFile -Force }

# Test attachment support - data (byte[])

Write-Output "Testing attachment create from byte array"
$testData = "Hello, byte array file!"
$testFileName = "hello_byte_array_file.txt"
$testFile = Join-Path -Path $PSScriptRoot -ChildPath $testFileName
if( Test-Path $testFile ) { Remove-Item $testFile -Force }
$testData | Out-File -FilePath $testFile
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes( $testFile )
Write-PowerPassAttachment -FileName $testFileName -Data $fileBytes
$readBytes = Read-PowerPassAttachment -FileName $testFileName
if( $fileBytes.Length -ne $readBytes.Length ) {
    Write-Warning "Test failed: byte array length mismatch"
} else {
    $match = $true
    for( $i = 0; $i -lt $fileBytes.Length; $i++ ) {
        $match = $match -and ( $fileBytes[$i] -eq $readBytes[$i] )
    }
    if( -not $match ) {
        Write-Warning "Test failed: byte array contents not identical"
    }
}
if( Test-Path $testFile ) { Remove-Item $testFile -Force }

# Test attachment support - data (Get-Content) by parameter

Write-Output "Testing attachment create from Get-Content by parameter"
Write-PowerPassAttachment -FileName "the_last_train.txt" -Data (Get-Content "$PSScriptRoot\thelasttrain.txt")
$readBytes = Read-PowerPassAttachment -FileName "the_last_train.txt"
$readString = ([System.Text.Encoding]::Unicode).GetString( $readBytes )
$fileString = Get-Content "$PSScriptRoot\thelasttrain.txt" -Raw
# Normalize the line endings because they are removed by Get-Content
$readString = $readString -replace "`r`n","`n"
$fileString = $fileString -replace "`r`n","`n"
if( $readString -ne $fileString ) {
    Write-Warning "Test failed: data read not identical to file"
    Write-Output "Read Data"
    Write-Output $readString
    Write-Output "File Data"
    Write-Output $fileString
}

# Test attachment support - data (Get-Content) by pipeline
# This cannot be implemented, because PowerShell's run-time sends one line from the file at a time
# into the Write-PowerPassAttachment rather than the entire array at once
#
# Get-Content "$PSScriptRoot\thelasttrain.txt" | Write-PowerPassAttachment -FileName "the_last_train.txt"
#

# Test attachment support - data (FileInfo)

Write-Output "Testing attachment create from FileInfo"
$testData = "Hello, file info!"
$testFileName = "hello_file_info.txt"
$testFile = Join-Path -Path $PSScriptRoot -ChildPath $testFileName
if( Test-Path $testFile ) { Remove-Item $testFile -Force }
$testData | Out-File -FilePath $testFile
$fileInfo = Get-ChildItem -Path $testFile
Write-PowerPassAttachment -FileName $testFileName -Data $fileInfo
$readBytes = Read-PowerPassAttachment -FileName $testFileName
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes( $testFile )
if( $fileBytes.Length -ne $readBytes.Length ) {
    Write-Warning "Test failed: byte array length mismatch"
} else {
    $match = $true
    for( $i = 0; $i -lt $fileBytes.Length; $i++ ) {
        $match = $match -and ( $fileBytes[$i] -eq $readBytes[$i] )
    }
    if( -not $match ) {
        Write-Warning "Test failed: byte array contents not identical"
    }
}
if( Test-Path $testFile ) { Remove-Item $testFile -Force }

# Test attachment support - data (string)

Write-Output "Testing attachment create from a string"
$testData = "Hello, file string!"
$testFileName = "hello_file_string.txt"
# Text data is encoded with Unicode before being stored in the locker
Write-PowerPassAttachment -FileName $testFileName -Data $testData
$readBytes = Read-PowerPassAttachment -FileName $testFileName
# The byte array returned must be decoded as Unicode
$readString = [System.Text.Encoding]::Unicode.GetString($readBytes)
if( $readString -ne $testData ) {
	Write-Warning "Test failed: test data and read string are not the same"
	Write-Output "testData   : $testData"
	Write-Output "readString : $readString"
}

# Test attachment support - data (PSCustomObject)

Write-Output "Testing attachment create from a PSCustomObject"
$testData = [PSCustomObject]@{
	Hello = "World!"
}
$testFileName = "hello_file_json.txt"
# PSCustomObject data is converted to JSON then encoded with Unicode before being stored in the locker
Write-PowerPassAttachment -FileName $testFileName -Data $testData
$readBytes = Read-PowerPassAttachment -FileName $testFileName
# The byte array returned must be decoded as Unicode
$readJson = [System.Text.Encoding]::Unicode.GetString($readBytes)
$readData = ConvertFrom-Json -InputObject $readJson
if( $testData.Hello -ne $readData.Hello ) {
	Write-Warning "Test failed: Hello properties are not identical"
}

# Test attachment support - data (other)

Write-Output "Testing attachment create from a custom object"
$codeFile = Join-Path -Path $PSScriptRoot -ChildPath "CustomObject.cs"
Add-Type -TypeDefinition (Get-Content $codeFile -Raw) -Language CSharp
$testData = New-Object -TypeName "PowerPass.CustomObject"
$testData.MyValue = "Hello, custom object!"
$testFileName = "hello_custom_object.txt"
# Custom object data is output using ToString() then encoded with Unicode before being stored in the locker
Write-PowerPassAttachment -FileName $testFileName -Data $testData
$readBytes = Read-PowerPassAttachment -FileName $testFileName
# The byte array returned must be decoded as Unicode
$readData = [System.Text.Encoding]::Unicode.GetString($readBytes)
if( $testData.MyValue -ne $readData ) {
	Write-Warning "Test failed: Hello properties are not identical"
}

# Test attachment support - pipeline data

Write-Output "Testing attachment create from pipeline data"
$testData = "Hello, pipeline data!"
$testFileName = "hello_pipeline_file.txt"
$testFile = Join-Path -Path $PSScriptRoot -ChildPath $testFileName
if( Test-Path $testFile ) { Remove-Item $testFile -Force }
$testData | Out-File -FilePath $testFile
# Pipe the file get operation to the write operation
Get-ChildItem -Path $testFile | Write-PowerPassAttachment -FileName $testFileName
$readBytes = Read-PowerPassAttachment -FileName $testFileName
[byte[]]$fileBytes = [System.IO.File]::ReadAllBytes( $testFile )
if( $fileBytes.Length -ne $readBytes.Length ) {
    Write-Warning "Test failed: byte array length mismatch"
} else {
    $match = $true
    for( $i = 0; $i -lt $fileBytes.Length; $i++ ) {
        $match = $match -and ( $fileBytes[$i] -eq $readBytes[$i] )
    }
    if( -not $match ) {
        Write-Warning "Test failed: byte array contents not identical"
    }
}
if( Test-Path $testFile ) { Remove-Item $testFile -Force }

# Test attachment support - positional parameters

Write-Output "Testing positional parameters"
Write-PowerPassAttachment "hello_positional_filename.txt" "Hello, positional world!"
$answer = Read-PowerPassAttachment "hello_positional_filename.txt" -AsText
if( $answer -ne "Hello, positional world!" ) {
    Write-Warning "Test failed: positional parameters result incorrect"
}

# Test adding multiple attachments from the file system

Write-Output "Testing bulk add attachments from file system"
Get-ChildItem $PSScriptRoot -File -Filter "*.ps1" | Add-PowerPassAttachment
$test1 = Read-PowerPassAttachment -FileName "Test-AesCrypto.ps1" -AsText -Encoding Utf8
$test2 = Read-PowerPassAttachment -FileName "Test-Attachments.ps1" -AsText -Encoding Utf8
$test3 = Read-PowerPassAttachment -FileName "Test-ModuleAes.ps1" -AsText -Encoding Utf8
$test4 = Read-PowerPassAttachment -FileName "Test-ModuleDpApi.ps1" -AsText -Encoding Utf8
$actual1 = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "Test-AesCrypto.ps1") -Raw
$actual2 = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "Test-Attachments.ps1") -Raw
$actual3 = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "Test-ModuleAes.ps1") -Raw
$actual4 = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "Test-ModuleDpApi.ps1") -Raw
if( $test1 -ne $actual1 ) {
    Write-Warning "Test 1 failed: file contents not identical"
}
if( $test2 -ne $actual2 ) {
    Write-Warning "Test 2 failed: file contents not identical"
}
if( $test3 -ne $actual3 ) {
    Write-Warning "Test 3 failed: file contents not identical"
}
if( $test4 -ne $actual4 ) {
    Write-Warning "Test 4 failed: file contents not identical"
}

# Test attachment removal - by parameter

Write-Output "Testing attachment removal by parameter"
$file = Read-PowerPassAttachment -FileName "Test-AesCrypto.ps1"
if( $file ) {
    # Expected
} else {
    Write-Warning "Test failed: locker does not contain test file"
}
Remove-PowerPassAttachment -FileName "Test-AesCrypto.ps1"
$file = Read-PowerPassAttachment -FileName "Test-AesCrypto.ps1"
if( $file ) {
    Write-Warning "Test failed: attachment not removed"
} else {
    # Expected
}

# Test attachment removal - by pipeline

Write-Output "Testing attachment removal by pipeline"
$file = Read-PowerPassAttachment -FileName "Test-Attachments.ps1"
if( $file ) {
    # Expected
} else {
    Write-Warning "Test failed: locker does not contain test file"
}
"Test-Attachments.ps1" | Remove-PowerPassAttachment 
$file = Read-PowerPassAttachment -FileName "Test-Attachments.ps1"
if( $file ) {
    Write-Warning "Test failed: attachment not removed"
} else {
    # Expected
}

# Test attachment import and export - current directory

Write-Output "Testing export of the default attachment"
$readData = Export-PowerPassAttachment -FileName "PowerPass.txt" | Get-Content -Raw
if( $readData -ne "This is the default text file attachment." ) {
    Write-Warning "Test failed: output file does not contain expected data"
}
Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "PowerPass.txt") -Force

# Test attachment import and export - current directory specific

Write-Output "Testing export to specified path"
$readData = Export-PowerPassAttachment -FileName "PowerPass.txt" -Path $PSScriptRoot | Get-Content -Raw
if( $readData -ne "This is the default text file attachment." ) {
    Write-Warning "Test failed: output file does not contain expected data"
}
Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "PowerPass.txt") -Force

# Test attachment import and export - add and export this whole directory

Write-Output "Testing attachment import and export"
Clear-PowerPassLocker -Force
Remove-PowerPassAttachment -FileName "PowerPass.txt"
$actualHash = Get-ChildItem -File | Get-FileHash
Get-ChildItem -File | Add-PowerPassAttachment -FullPath
Export-PowerPassAttachment -FileName "*" -OriginalPath -Force
foreach( $ath in $actualHash ) {
    $hash = Get-FileHash -Path ($ath.Path)
    if( $hash.Hash -ne $ath.Hash ) {
        Write-Warning "Test failed: $($ath.Path) not identical"
    }
}

# Test attachment import and export - add and export this whole directory - GZip enabled

Write-Output "Testing attachment import and export with GZip"
Clear-PowerPassLocker -Force
Remove-PowerPassAttachment -FileName "PowerPass.txt"
$actualHash = Get-ChildItem -File | Get-FileHash
Get-ChildItem -File | Add-PowerPassAttachment -FullPath -GZip
Export-PowerPassAttachment -FileName "*" -OriginalPath -Force
foreach( $ath in $actualHash ) {
    $hash = Get-FileHash -Path ($ath.Path)
    if( $hash.Hash -ne $ath.Hash ) {
        Write-Warning "Test failed: $($ath.Path) not identical"
    }
}

Clear-PowerPassLocker -Force