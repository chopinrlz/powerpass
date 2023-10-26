<#
    Salt shaker for PowerPass, generates a per-install 256-bit unique salt
    Copyright 2023 by The Daltas Group LLC.
    The KeePassLib source code is copyright (C) 2003-2023 Dominik Reichl <dominik.reichl@t-online.de>
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

$saltShaker = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = [System.Byte[]]::CreateInstance( [System.Byte], 32 )
$saltShaker.GetBytes( $salt )
$saltText = $salt -join ","
Out-File -InputObject $saltText -FilePath "$PSScriptRoot\salt" -Force