#
# Common Information Model (CIM) export utility
#
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#
$file = Join-Path -Path $PSScriptRoot -ChildPath "cim.json"
if( Test-Path $file ) {
    Remove-Item -Path $file
}
Get-CimClass | ? CimClassName -eq "CIM_Processor" | % {
    Get-CimInstance -ClassName ($_.CimClassName) | ConvertTo-Json -Depth 99 | Out-File "$file" -Append
}