<#
    Test script for the AesCrypto.cs class of PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Import the source code

$code = Get-Content "$PSScriptRoot\..\module\AesCrypto.cs" -Raw
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Security"
} else {
    Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Security.Cryptography"
}

# Generate test data

$password = New-PowerPassRandomPassword -Length 32
$keyFile = "$PSScriptRoot\aes.key"
$encryptedFile = "$PSScriptRoot\data.aes"
$data = [System.Guid]::NewGuid().ToString()
$dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)

# Test - key generation, writing and reading keys from disk

$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.GenerateKey()
$secret = [System.Text.Encoding]::UTF8.GetBytes($password)
$aes.WriteKeyToDisk( $keyFile, [ref] $secret )
$secret = [System.Text.Encoding]::UTF8.GetBytes($password)
$aes.ReadKeyFromDisk( $keyFile, [ref] $secret )
$aes.Dispose()

# Delete previous keys

if( Test-Path $keyFile ) {
    Remove-Item $keyFile -Force
}

# Test - encryption and decryption

$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.GenerateKey()
$aes.Encrypt( $dataBytes, $encryptedFile )
$checkDataBytes = $aes.Decrypt( $encryptedFile )
$checkData = [System.Text.Encoding]::UTF8.GetString($checkDataBytes)
if( -not ([System.String]::Equals( $data, $checkData, "Ordinal" )) ) {
    Write-Warning "Test failed: decryption"
}
$aes.Dispose()

# Test - write key then encrypt

$aes = New-Object -TypeName "PowerPass.AesCrypto"
$secret = [System.Text.Encoding]::UTF8.GetBytes($password)
$aes.WriteKeyToDisk( $keyFile, [ref] $secret )
$aes.Encrypt( $dataBytes, $encryptedFile )
$aes.Dispose()

# Test - read key then decrypt

$aes = New-Object -TypeName "PowerPass.AesCrypto"
$secret = [System.Text.Encoding]::UTF8.GetBytes($password)
$aes.ReadKeyFromDisk( $keyFile, [ref] $secret )
$checkDataBytes = $aes.Decrypt( $encryptedFile )
$checkData = [System.Text.Encoding]::UTF8.GetString($checkDataBytes)
if( -not ([System.String]::Equals( $data, $checkData, "Ordinal" )) ) {
    Write-Warning "Test failed: read key from disk"
}
$aes.Dispose()

# Test - read large file then encrypt and decrypt

$data = Get-Content "$PSScriptRoot\thelasttrain.txt" -Raw
$dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.DecryptionBufferSize = 1024
$aes.GenerateKey()
$aes.Encrypt( $dataBytes, $encryptedFile )
$checkDataBytes = $aes.Decrypt( $encryptedFile )
$checkData = [System.Text.Encoding]::UTF8.GetString($checkDataBytes)
if( -not ([System.String]::Equals( $data, $checkData, "Ordinal" )) ) {
    Write-Warning "Test failed: large file encrypt and decrypt"
}

# Clean up temporary files

if( Test-Path $keyFile ) { Remove-Item $keyFile -Force }
if( Test-Path $encryptedFile ) { Remove-Item $encryptedFile -Force }