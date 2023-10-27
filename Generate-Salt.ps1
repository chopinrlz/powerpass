<#
    Salt shaker for PowerPass, generates a per-install 256-bit unique salt and encrypts it with the machine key
    Copyright 2023 by The Daltas Group LLC.
    The KeePassLib source code is copyright (C) 2003-2023 Dominik Reichl <dominik.reichl@t-online.de>
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Load the System.Security assembly from the .NET Framework
[System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null

# Generate a salt using a random number generator
$saltShaker = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = [System.Byte[]]::CreateInstance( [System.Byte], 32 )
$saltShaker.GetBytes( $salt )

# Encrypt the salt using the machine key
$encSalt = [System.Security.Cryptography.ProtectedData]::Protect($salt,$null,"LocalMachine")

# Save the encrypted salt to a salt file in the byte collection format
$saltText = $encSalt -join ","
Out-File -InputObject $saltText -FilePath "$PSScriptRoot\powerpass.salt" -Force