#
# Common Information Model (CIM) export utility
#
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#
param(
    [string]
    $Class = "CIM_Processor"
)
if( $PSVersionTable.PSVersion.Major -gt 5 ) {
    throw "This script requires Windows PowerShell 5.1"
}
$file = Join-Path -Path $PSScriptRoot -ChildPath "cim.json"
if( Test-Path $file ) {
    Remove-Item -Path $file -Force
}
Get-CimClass | ? CimClassName -eq $Class | % {
    Get-CimInstance -ClassName ($_.CimClassName) | ConvertTo-Json -Depth 99 | Out-File "$file" -Append
}