# PowerPass startup script
# Copyright 2023-2025 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.

if( $PSVersionTable.PSVersion.Major -lt 5 ) {
	Write-Warning "PowerPass requires Windows PowerShell 5.1 or PowerShell 7"
}