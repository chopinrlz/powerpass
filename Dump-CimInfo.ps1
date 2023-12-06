$file = Join-Path -Path $PSScriptRoot -ChildPath "cim.json"
if( Test-Path $file ) {
    Remove-Item -Path $file
}
Get-CimClass | ? CimClassName -eq "CIM_Processor" | % {
    Get-CimInstance -ClassName ($_.CimClassName) | ConvertTo-Json -Depth 99 | Out-File "$file" -Append
}