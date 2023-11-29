Write-Host "This script tests the AesCrypto.cs implementation"
Write-Host "These tests should pass in both Windows PowerShell and PowerShell 7 on all operating systems"

Write-Host "Loading the type from source"
$code = Get-Content "$PSScriptRoot\..\PowerPass\AesCrypto.cs" -Raw
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Security"
} else {
    Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Security.Cryptography"
}

Write-Host "Setting up constants for testing"
$keyFile = "$PSScriptRoot\aes.key"
$encryptedFile = "$PSScriptRoot\data.aes"
$data = [System.Guid]::NewGuid().ToString()
$dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)

Write-Host "Testing key generation"
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.GenerateKey()
$aes.WriteKeyToDisk( $keyFile )
$aes.ReadKeyFromDisk( $keyFile )

Write-Host "Testing automatic key generation"
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.WriteKeyToDisk( $keyFile )
$aes.ReadKeyFromDisk( $keyFile )

Write-Host "Testing dispose"
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.Dispose()
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.GenerateKey()
$aes.Dispose()

Write-Host "Testing encryption/decryption: " -NoNewline
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.GenerateKey()
$aes.Encrypt( $dataBytes, $encryptedFile )
$checkDataBytes = $aes.Decrypt( $encryptedFile )
$checkData = [System.Text.Encoding]::UTF8.GetString($checkDataBytes)
if( [System.String]::Equals( $data, $checkData, "Ordinal" ) ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}

Write-Host "Testing decryption with loaded key: " -NoNewline
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.WriteKeyToDisk( $keyFile )
$aes.Encrypt( $dataBytes, $encryptedFile )
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.ReadKeyFromDisk( $keyFile )
$checkDataBytes = $aes.Decrypt( $encryptedFile )
$checkData = [System.Text.Encoding]::UTF8.GetString($checkDataBytes)
if( [System.String]::Equals( $data, $checkData, "Ordinal" ) ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}

Write-Host "Testing large file encryption/decryption: " -NoNewline
$data = Get-Content "$PSScriptRoot\thelasttrain.txt" -Raw
$dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.DecryptionBufferSize = 1024
$aes.GenerateKey()
$aes.Encrypt( $dataBytes, $encryptedFile )
$checkDataBytes = $aes.Decrypt( $encryptedFile )
$checkData = [System.Text.Encoding]::UTF8.GetString($checkDataBytes)
$checkData | Out-File "$PSScriptRoot\checkdata.txt" -Force
if( [System.String]::Equals( $data, $checkData, "Ordinal" ) ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}