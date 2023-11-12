$keyFile = "$PSScriptRoot\aes.key"
$code = Get-Content "$PSScriptRoot\..\PowerPass\AesCrypto.cs" -Raw
Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Security.Cryptography","System.Console"

Write-Host "Testing key generation: " -NoNewline
$aes = New-Object -TypeName "PowerPass.AesCrypto"
$aes.GenerateKey()
$keyString = [System.Convert]::ToBase64String( $aes.Key )
$aes.WriteKeyToDisk( $keyFile )
$aes.Key = $null
$aes.ReadKeyFromDisk( $keyFile )
$checkKeyString = [System.Convert]::ToBase64String( $aes.Key )
if( [System.String]::Equals( $keyString, $checkKeyString, "Ordinal" ) ) {
    Write-Host "Assert passed"
} else {
    Write-Warning "Assert failed"
}

Write-Host "Testing encryption/decryption: " -NoNewline
$encryptedFile = "$PSScriptRoot\data.aes"
$data = "Hello, world!"
$dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)
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

Write-Host "Testing large file encryption/decryption: " -NoNewline
$data = Get-Content "$PSScriptRoot\thelasttrain.txt" -Raw
$dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)
$aes = New-Object -TypeName "PowerPass.AesCrypto"
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