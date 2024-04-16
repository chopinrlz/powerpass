Get-Date
$name = "random.bin"
Write-Host "Creating Path to $name test file"
$file = Join-Path -Path $PSScriptRoot -ChildPath $name
Write-Host "Reading all file bytes into memory"
$bytes = [System.IO.File]::ReadAllBytes( $file )
Write-Host "Converting file bytes to base64 string"
$base64 = [System.Convert]::ToBase64String( $bytes )
Write-Host "Converting base64 string back to file bytes"
$bytes = [System.Convert]::FromBase64String( $base64 )
Write-Host "Test complete"
Get-Date