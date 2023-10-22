# PowerPass startup script
# Copyright 2023 by The Daltas Group LLC. All rights reserved.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
if( $PSVersion.PSVersion.Major -ne 5 ) {
    Write-Warning "This module can only be used with PowerShell 5.1."
}