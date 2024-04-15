Get-Date
Write-Host "Creating Path to dotnet.exe test file"
$file = Join-Path -Path $PSScriptRoot -ChildPath "dotnet.exe"
Write-Host "Reading all file bytes into memory"
$bytes = [System.IO.File]::ReadAllBytes( $file )
Write-Host "Converting file bytes to base64 string"
$base64 = [System.Convert]::ToBase64String( $bytes )
Write-Host "Converting base64 string back to file bytes"
$bytes = [System.Convert]::FromBase64String( $base64 )
Write-Host "Test complete"
Get-Date