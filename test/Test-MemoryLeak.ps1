$name = "random.bin"

$start = Get-Date

Write-Host "Creating Path to $name test file: " -NoNewline
$now = Get-Date
$file = Join-Path -Path $PSScriptRoot -ChildPath $name
Write-Host " $(((Get-Date) - $now).TotalMilliseconds) ms"

Write-Host "Reading all file bytes into memory: " -NoNewline
$now = Get-Date
$bytes = [System.IO.File]::ReadAllBytes( $file )
Write-Host " $(((Get-Date) - $now).TotalMilliseconds) ms"

Write-Host "Converting file bytes to base64 string: " -NoNewline
$now = Get-Date
$base64 = [System.Convert]::ToBase64String( $bytes )
Write-Host " $(((Get-Date) - $now).TotalMilliseconds) ms"

Read-Host "Attach debugger now then press Enter"

Write-Host "Converting base64 string back to file bytes: " -NoNewline
$now = Get-Date
$bytes = [System.Convert]::FromBase64String( $base64 )
Write-Host " $(((Get-Date) - $now).TotalMilliseconds) ms"

Write-Host "Test complete"

Write-Host "Total duration: $(((Get-Date) - $start).TotalMilliseconds) ms"