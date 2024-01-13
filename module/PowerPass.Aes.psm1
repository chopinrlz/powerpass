<#
    AES block cipher implementation of the PowerPass PowerShell module for PowerShell and Windows PowerShell
    Copyright 2023-2024 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Setup the constants for this module
$PowerPassEdition = "powerpassv2"
$LockerFileName = ".powerpass_locker"
$LockerKeyFileName = ".locker_key"

# Determine where application data should be stored
$AppDataPath  = if( $IsLinux ) {
    [System.Environment]::GetFolderPath("ApplicationData")
} else {
    [System.Environment]::GetFolderPath("LocalApplicationData")
}

# Determine where user data should be stored
$UserDataPath = if( $IsLinux -or $IsMacOS ) {
    [System.Environment]::GetFolderPath("UserProfile")
} else {
    [System.Environment]::GetFolderPath("Personal")
}

# Setup the root module object in script scope and load all relevant properties
$PowerPass = [PSCustomObject]@{
    AesCryptoSourcePath = Join-Path -Path $PSScriptRoot -ChildPath "AesCrypto.cs"
    CommonSourcePath    = Join-Path -Path $PSScriptRoot -ChildPath "PowerPass.Common.ps1"
    LockerFolderPath    = $UserDataPath
    LockerFilePath      = Join-Path -Path $UserDataPath -ChildPath $LockerFileName
    LockerKeyFolderPath = Join-Path -Path $AppDataPath -ChildPath $PowerPassEdition
    LockerKeyFilePath   = Join-Path -Path $AppDataPath -ChildPath "$PowerPassEdition/$LockerKeyFileName"
    Implementation      = "AES"
}

# Compile and load the AesCrypto implementation
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    Add-Type -Path $PowerPass.AesCryptoSourcePath -ReferencedAssemblies "System.Security"
} else {
    Add-Type -Path $PowerPass.AesCryptoSourcePath -ReferencedAssemblies "System.Security.Cryptography"
}

# Dot Source the common functions
. ($PowerPass.CommonSourcePath)

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Clear-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Clear-PowerPassLocker {
    <#
        .SYNOPSIS
        Deletes all your locker secrets and your locker key. PowerPass will generate a new locker and key
        for you the next time you write or read secrets to or from your locker.
        .PARAMETER Force
        WARNING: If you specify Force, your locker and salt will be removed WITHOUT confirmation.
    #>
    param(
        [switch]
        $Force
    )
    if( $Force ) {
        if( Test-Path ($script:PowerPass.LockerFilePath) ) {
            Remove-Item -Path ($script:PowerPass.LockerFilePath) -Force
        }
        if( Test-Path ($script:PowerPass.LockerKeyFilePath) ) {
            Remove-Item -Path ($script:PowerPass.LockerKeyFilePath) -Force
        }
    } else {
        $answer = Read-Host "WARNING: You are about to DELETE your PowerPass locker. All your secrets and attachments will be erased. This CANNOT be undone. Do you want to proceed [N/y]?"
        if( Test-PowerPassAnswer $answer ) {
            $answer = Read-Host "CONFIRM: Please confirm again with Y or y to delete your PowerPass locker [N/y]"
            if( Test-PowerPassAnswer $answer ) {
                Write-Host "Deleting your PowerPass locker"
                if( Test-Path ($script:PowerPass.LockerFilePath) ) {
                    Remove-Item -Path ($script:PowerPass.LockerFilePath) -Force
                }
                if( Test-Path ($script:PowerPass.LockerKeyFilePath) ) {
                    Remove-Item -Path ($script:PowerPass.LockerKeyFilePath) -Force
                }
            } else {
                Write-Host "Cancelled, locker not deleted"
            }
        } else {
            Write-Host "Cancelled, locker not deleted"
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassLocker {
    <#
        .SYNOPSIS
        Retrieves the PowerPass locker for the current user from the file system and initializes it if it does
        not already exist.
        .OUTPUTS
        Writes the locker to the pipeline if it exists, otherwise writes $null to the pipeline.
        .NOTES
        This cmdlet will stop execution with a throw if the locker salt could not be fetched.
    #>
    Initialize-PowerPassLocker
    $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( Test-Path $pathToLocker ) {
        if( Test-Path $pathToLockerKey ) {
            $aes = New-Object -TypeName "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $lockerBytes = $aes.Decrypt( $pathToLocker )
            $lockerJson = [System.Text.Encoding]::UTF8.GetString( $lockerBytes )
            $locker = ConvertFrom-Json $lockerJson
            $aes.Dispose()
            Write-Output $locker
        } else {
            Write-Output $null
        }
    } else {
        Write-Output $null
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Write-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Write-PowerPassSecret {
    <#
        .SYNOPSIS
        Writes one or more secrets into your PowerPass locker.
        .PARAMETER Title
        Mandatory. The Title of the secret. This is unique to your locker. If you already have a secret in your
        locker with this Title, it will be updated, but only the parameters you specify will be updated.
        .PARAMETER UserName
        Optional. Sets the UserName property of the secret in your locker.
        .PARAMETER Password
        Optional. Sets the Password property of the secret in your locker.
        .PARAMETER URL
        Optional. Sets the URL property of the secret in your locker.
        .PARAMETER Notes
        Optional. Sets the Notes property of the secret in your locker.
        .PARAMETER Expires
        Optional. Sets the Expiras property of the secret in your locker.
        .PARAMETER MaskPassword
        An optional switch that, when specified, will prompt you to enter a password rather than having to use the Password parameter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [string]
        $Title,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $UserName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Password,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $URL,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Notes,
        [Parameter(ValueFromPipelineByPropertyName)]
        [DateTime]
        $Expires = [DateTime]::MaxValue,
        [switch]
        $MaskPassword
    )
    begin {
        $locker = Get-PowerPassLocker
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        $changed = $false
    } process {
        $existingSecret = $locker.Secrets | Where-Object { $_.Title -eq $Title }
        if( $existingSecret ) {
            if( $UserName ) {
                $existingSecret.UserName = $UserName
                $changed = $true
            }
            if( $Password ) {
                $existingSecret.Password = $Password
                $changed = $true
            }
            if( $MaskPassword ) {
                $existingSecret.Password = Get-PowerPassMaskedPassword -Prompt "Enter the Password for the secret"
                $changed = $true
            }
            if( $URL ) {
                $existingSecret.URL = $URL
                $changed = $true
            }
            if( $Notes ) {
                $existingSecret.Notes = $Notes
                $changed = $true
            }
            if( $Expires -ne ($existing.Expires) ) {
                $existingSecret.Expires = $Expires
                $changed = $true
            }
            if( $changed ) {
                $existingSecret.Modified = (Get-Date).ToUniversalTime()
            }
        } else {
            $changed = $true
            $newSecret = New-PowerPassSecret
            $newSecret.Title = $Title
            $newSecret.UserName = $UserName
            $newSecret.Password = $Password
            if( $MaskPassword ) {
                $newSecret.Password = Get-PowerPassMaskedPassword -Prompt "Enter the Password for the secret"
                $changed = $true
            }
            $newSecret.URL = $URL
            $newSecret.Notes = $Notes
            $newSecret.Expires = $Expires
            $locker.Secrets += $newSecret
        }
    } end {
        if( $changed ) {
            $pathToLocker = $script:PowerPass.LockerFilePath
            $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
            $data = Get-PowerPassLockerBytes -Locker $locker
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Read-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Read-PowerPassSecret {
    <#
        .SYNOPSIS
        Reads secrets from your PowerPass locker.
        .PARAMETER Match
        An optional filter. If specified, only secrets whose Title matches this filter are output to the pipeline.
        Cannot be combined with Title as Title will be ignored if Match is specified.
        .PARAMETER Title
        An optional exact match filter. If specified, only the secret which exactly matches the Title will be
        output to the pipeline. Do not combine with Match as Title will be ignored if Match is specified.
        .PARAMETER PlainTextPasswords
        An optional switch which instructs PowerPass to output the passwords in plain-text. By default, all
        passwords are output as SecureString objects. You cannot combine this with AsCredential.
        .PARAMETER AsCredential
        An optional switch which instructs PowerPass to output the secrets as PSCredential objects. You cannot
        combine this with PlainTextPasswords.
        .OUTPUTS
        This cmdlet outputs PowerPass secrets from your locker to the pipeline. Each secret is a PSCustomObject
        with these properties:
        1. Title     - the name, or title, of the secret, this value is unique to the locker
        2. UserName  - the username field string for the secret
        3. Password  - the password field for the secret, by default a SecureString
        4. URL       - the URL string for the secret
        5. Notes     - the notes string for the secret
        6. Expires   - the expiration date for the secret, by default December 31, 9999
        7. Created   - the date and time the secret was created in the locker
        8. Modified  - the date and time the secret was last modified
        .NOTES
        When you use PowerPass for the first time, PowerPass creates a default secret in your locker with the
        Title "Default" with all fields populated as an example of the data structure stored in the locker.
        You can delete or change this secret by using Write-PowerPassSecret or Delete-PowerPassSecret and specifying
        the Title of "Default".
    #>
    param(
        [Parameter(ValueFromPipeline,Position=0)]
        [string]
        $Match,
        [string]
        $Title,
        [switch]
        $PlainTextPasswords,
        [switch]
        $AsCredential
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    if( $locker.Secrets ) {
        if( $Match ) {
            $secrets = $locker.Secrets | Where-Object { $_.Title -like $Match }
            if( $PlainTextPasswords ) {
                Write-Output $secrets
            } else {
                if( $AsCredential ) {
                    $secrets | Get-PowerPassCredential
                } else {
                    $secrets | Set-PowerPassSecureString
                }
            }
        } elseif( $Title ) {
            foreach( $secret in $locker.Secrets ) {
                if( $secret.Title -eq $Title ) {
                    if( $PlainTextPasswords ) {
                        Write-Output $secret
                    } else {
                        if( $AsCredential ) {
                            $secret | Get-PowerPassCredential
                        } else {
                            $secret | Set-PowerPassSecureString
                        }
                    }
                }
            }
        } else {
            if( $PlainTextPasswords ) {
                Write-Output $locker.Secrets
            } else {
                if( $AsCredential ) {
                    $locker.Secrets | Get-PowerPassCredential
                } else {
                    $locker.Secrets | Set-PowerPassSecureString
                }
            }
        }
    } else {
        Write-Output $null
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Initialize-PowerPassUserDataFolder
# ------------------------------------------------------------------------------------------------------------- #

function Initialize-PowerPassUserDataFolder {
    <#
        .SYNOPSIS
        Checks for the PowerPass data folder in the user's profile directory and creates it if it does not exist.
        .INPUTS
        This cmdlet does not take any input.
        .OUTPUTS
        This cmdlet does not output anything.
        .NOTES
        This cmdlet will break execution with a throw if the data folder could not be created.
    #>
    if( -not (Test-Path ($script:PowerPass.LockerFolderPath) ) ) {
        throw "You do not have a personal documents folder"
    }
    if( -not (Test-Path ($script:PowerPass.LockerKeyFolderPath) ) ) {
        New-Item -Path $script:AppDataPath -Name $script:PowerPassEdition -ItemType Directory | Out-Null
        if( -not (Test-Path ($script:PowerPass.LockerKeyFolderPath)) ) {
            throw "Cannot write to user data path to create data folder"
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Initialize-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Initialize-PowerPassLocker {
    <#
        .SYNOPSIS
        Creates a PowerPass locker file and encrypts it using the locker salt and the Data Protection API.
        Does not overwrite an existing locker file.
        .INPUTS
        This cmdlet does not take any input.
        .OUTPUTS
        This cmdlet does not output anything. It writes the locker file to disk.
        .NOTES
        The locker file is populated with one Default secret and one default attachment named PowerPass.txt.
        This cmdlet will halt execution with a throw if the locker salt has not been initialized, or cannot
        be loaded, or if the locker file could not be written to the user data directory.
    #>
    Initialize-PowerPassUserDataFolder
    $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
    if( -not (Test-Path $pathToLockerKey) ) {
        $aes = New-Object -TypeName "PowerPass.AesCrypto"
        $aes.GenerateKey()
        $aes.WriteKeyToDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
        $aes.Dispose()
    }
    if( -not (Test-Path $pathToLockerKey) ) {
        throw "Cannot write to app data path to initialize key file"
    }
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( -not (Test-Path $pathToLocker) ) {
        $locker = New-PowerPassLocker -Populated
        $data = Get-PowerPassLockerBytes $locker
        $aes = New-Object -TypeName "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
        $aes.Encrypt( $data, $pathToLocker )
        $aes.Dispose()
    }
    if( -not (Test-Path $pathToLocker) ) {
        throw "Failed to initialize the user's locker"
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Export-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Export-PowerPassLocker {
    <#
        .SYNOPSIS
        Exports your PowerPass Locker to an encrypted backup file powerpass_locker.bin.
        .DESCRIPTION
        You will be prompted to enter a password to encrypt the locker. The password must be
        between 4 and 32 characters.
        .PARAMETER Path
        The path where the exported file will go. This is mandatory, and this path must exist.
        .OUTPUTS
        This cmdlet does not output to the pipeline. It creates the file powerpass_locker.bin
        in the target Path. If the file already exists, you will be prompted to replace it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $Path
    )
    if( -not (Test-Path $Path) ) {
        throw "$Path does not exist"
    }
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not load you PowerPass locker"
    }
    $password = ""
    if( $PSVersionTable.PSVersion.Major -eq 5 ) {
        $secString = Read-Host "Enter a password (4 - 32 characters)" -AsSecureString
        $bString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $secString )
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto( $bString )
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR( $bString )
    } else {
        $password = Read-Host -Prompt "Enter a locker password (4 - 32 characters)" -MaskInput
    }
    if( $password -eq "" ) {
        throw "You cannot use a blank password"
    }
    if( ($password.Length -lt 4) -or ($password.Length -gt 32) ) {
        throw "The password must be between 4 and 32 characters."
    }
    $output = Join-Path -Path $Path -ChildPath "powerpass_locker.bin"
    if( Test-Path $output ) {
        $answer = Read-Host "$output already exists, overwrite? [N/y]"
        if( Test-PowerPassAnswer $answer ) {
            Remove-Item -Path $output
        } else {
            throw "Export cancelled by user"
        }
    }
    $data = Get-PowerPassLockerBytes $locker
    $aes = New-Object -TypeName "PowerPass.AesCrypto"
    $aes.SetPaddedKey( $password )
    $aes.Encrypt( $data, $output )
    $aes.Dispose()
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Import-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Import-PowerPassLocker {
    <#
        .SYNOPSIS
        Imports a PowerPass locker file.
        .DESCRIPTION
        You will be prompted to enter the locker password.
        .PARAMETER LockerFile
        The path to the locker file on disk to import.
        .PARAMETER Force
        Import the locker files without prompting for confirmation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $LockerFile,
        [switch]
        $Force
    )

    # Define variables
    [bool]$warn = $false
    [byte[]]$data = $null

    # Prompt for password
    $password = ""
    if( $PSVersionTable.PSVersion.Major -eq 5 ) {
        $secString = Read-Host "Enter the locker password" -AsSecureString
        $bString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $secString )
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto( $bString )
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR( $bString )
    } else {
        $password = Read-Host -Prompt "Enter the locker password" -MaskInput
    }

    # Verify and load locker backup file
    if( Test-Path $LockerFile ) {
        $aes = New-Object -TypeName "PowerPass.AesCrypto"
        $aes.SetPaddedKey( $password )
        $data = $aes.Decrypt( $LockerFile )
        $aes.Dispose()
    } else {
        throw "$LockerFile does not exist"
    }
    if( -not $data ) {
        throw "Decryption failed"
    }

    # Check for existing locker
    if( Test-Path ($script:PowerPass.LockerFilePath) ) {
        $warn = if( $Force ) { $false } else { $true }
    } else {
        Initialize-PowerPassLocker
        $warn = $false
    }

    # Check for warning message
    if( $warn ) {
        $answer = Read-Host "You are about to overwrite your existing locker. Proceed? [N/y]"
        if( Test-PowerPassAnswer $answer ) { 
            Write-Output "Restoring locker from $LockerFile"
        } else {
            throw "Import cancelled by user"
        }
    }

    # Import the locker
    $aes = New-Object "PowerPass.AesCrypto"
    $aes.ReadKeyFromDisk( $script:PowerPass.LockerKeyFilePath, [ref] (Get-PowerPassEphemeralKey) )
    $aes.Encrypt( $data, $script:PowerPass.LockerFilePath )
    $aes.Dispose()
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Update-PowerPassKey
# ------------------------------------------------------------------------------------------------------------- #

function Update-PowerPassKey {
    <#
        .SYNOPSIS
        Rotates the Locker key to a new random key.
        .DESCRIPTION
        As a reoutine precaution, key rotation is recommended as a best practice when dealing with sensitive,
        encrypted data. When you rotate a key, PowerPass reencrypts your PowerPass Locker with a new random
        key. This ensures that even if a previous encryption was broken, a new attempt must be made if an
        attacker regains access to your encrypted Locker.
    #>
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Unable to fetch your PowerPass Locker"
    }
    Remove-Item -Path $script:PowerPass.LockerKeyFilePath -Force
    if( Test-Path $script:PowerPass.LockerKeyFilePath ) {
        throw "Could not delete Locker key file"
    }
    $aes = New-Object -TypeName "PowerPass.AesCrypto"
    $aes.GenerateKey()
    $aes.WriteKeyToDisk( $script:PowerPass.LockerKeyFilePath, [ref] (Get-PowerPassEphemeralKey) )
    $data = Get-PowerPassLockerBytes $locker
    $aes.Encrypt( $data, $script:PowerPass.LockerFilePath )
    $aes.Dispose()
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPass
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPass {
    <#
        .SYNOPSIS
        Gets all the information about this PowerPass deployment.
        .OUTPUTS
        A PSCustomObject with these properties:
            AesCryptoSourcePath : The path on disk to the AesCrypto.cs source code
            LockerFolderPath    : The folder where your locker is stored
            LockerFilePath      : The absolute path to your PowerPass locker on disk
            LockerKeyFolderPath : The folder where your locker key is stored
            LockerKeyFilePath   : The absolute path to your PowerPass locker key file
            Implementation      : The implementation you are using, either AES or DPAPI
    #>
    $PowerPass
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Remove-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Remove-PowerPassSecret {
    <#
        .SYNOPSIS
        Removes a secret from your locker.
        .PARAMETER Title
        The Title of the secret to remove from your locker.
        .NOTES
        The Title parameter can be passed from the pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $Title
    )
    begin {
        $locker = Get-PowerPassLocker
        if( -not $locker ) {
            throw "Could not load your PowerPass locker"
        }
        $newLocker = New-PowerPassLocker
        $newLocker.Created = $locker.Created
        # Old lockers do not have a modified flag
        if( $locker.Modified ) {
            $newLocker.Modified = $locker.Modified
        }
        $newLocker.Attachments = $locker.Attachments
        $changed = $false
    } process {
        foreach( $s in $locker.Secrets ) {
            if( ($s.Title) -eq $Title ) {
                $s.Mfd = $true
                $changed = $true
            }
        }
    } end {
        if( $changed ) {
            $newLocker.Secrets = $locker.Secrets | Where-Object { -not ($_.Mfd) }
            $pathToLocker = $script:PowerPass.LockerFilePath
            $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
            $data = Get-PowerPassLockerBytes $newLocker
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassEphemeralKey
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassEphemeralKey {
    <#
        .SYNOPSIS
        Creates an ephemeral key using the username, hostname, and primary MAC address of the current
        user and local system, respectively.
    #>
    if( $PSVersionTable.PSVersion.Major -eq 5 ) {
        # Legal in PowerShell 5, ignore warning
        $IsWindows = $true
    }
    [string]$hostName = & hostname
    [string]$userName = & whoami
    [string]$macAddress = ""
    if( $IsLinux -or $IsMacOS ) {
        $macRegEx = "([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}){1}"
        $mac = & ifconfig | grep -E ether
        if( $mac ) {
            $macAddress = (Select-String -InputObject $mac -Pattern $macRegEx).Matches[0].Value
        } else {
            throw "Could not locate an Ethernet adapter with ifconfig"
        }
    } elseif( $IsWindows ) {
        $nics = Get-CimInstance -ClassName "CIM_NetworkAdapter" | ? PhysicalAdapter
        if( $nics ) {
            if( $nics.Count -gt 1 ) {
                $nics = $nics[0]
            }
            $macAddress = $nics.MACAddress
        } else {
            throw "Could not locate an Ethernet adapter with CIM"
        }
    } else {
        throw "This script will only support MacOS, Linux and Windows at the moment"
    }
    if( -not $hostName ) { throw "No hostname found" }
    if( -not $userName ) { throw "No username found" }
    if( -not $macAddress ) { throw "No MAC address found" }
    $compKey = "$hostName|$userName|$macAddress"
    $compKeyBytes = [System.Text.Encoding]::UTF8.GetBytes( $compKey )
    $sha = [System.Security.Cryptography.Sha256]::Create()
    Write-Output $sha.ComputeHash( $compKeyBytes )
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Write-PowerPassAttachment
# ------------------------------------------------------------------------------------------------------------- #

function Write-PowerPassAttachment {
    <#
        .SYNOPSIS
        Writes an attachment into your locker.
        .PARAMETER FileName
        The name of the file to write into your locker. If this file already exists, it will be updated.
        .PARAMETER Path
        Option 1: you may specify the Path to a file on disk.
        .PARAMETER LiteralPath
        Option 2: you may specify the LiteralPath to a file on disk.
        .PARAMETER Data
        Option 3: you may specify the Data for the file in any format, or from the pipeline such as from Get-ChildItem.
        .PARAMETER Text
        Option 4: you may specify the contents of the file as a text string.
        .NOTES
        Data and Text in string format is encoded with Unicode. Data in PSCustomObject format is converted to JSON then
        encoded with Unicode. Byte arrays and FileInfo objects are stored natively. Data in any other formats is converted
        to a string using the build-in .NET ToString function then encoded with Unicode. To fetch text back from your locker
        saved as attachments use the -AsText parameter of Read-PowerPassAttachment to ensure the correct encoding is used.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]
        $FileName,
        [Parameter(ParameterSetName="FromDisk")]
        [string]
        $Path,
        [Parameter(ParameterSetName="FromDiskLiteral")]
        [string]
        $LiteralPath,
        [Parameter(ParameterSetName="FromPipeline",ValueFromPipeline)]
        $Data,
        [Parameter(ParameterSetName="FromString",Position=1)]
        [string]
        $Text
    )
    begin {
        $locker = Get-PowerPassLocker
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
    } process {
        [byte[]]$bytes = $null
        if( $Path ) {
            $bytes = Get-Content -Path $Path -Encoding Byte
        } elseif( $LiteralPath ) {
            $bytes = Get-Content -LiteralPath $LiteralPath -Encoding Byte
        } elseif( $Data ) {
            $dataType = $Data.GetType().FullName
            switch( $dataType ) {
                "System.Object[]" {
                    # Here we assume what happened is the caller ran Get-Content and it returned a
                    # text file as an array of strings which is the default behavior. We also need
                    # to guess what the file's hard return is since it has been removed from the
                    # data itself by Get-Content.
                    $hardReturn = "`r`n"
                    if( $IsLinux -or $IsMacOS ) {
                        $hardReturn = "`n"
                    }
                    $sb = New-Object "System.Text.StringBuilder"
                    for( $i = 0; $i -lt ($Data.Length - 1); $i++ ) {
                        $null = $sb.Append( $Data[$i].ToString() ).Append( $hardReturn )
                    }
                    # Avoid adding an extra hard return to the end of the data
                    $null = $sb.Append( $Data[-1].ToString() )
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $sb.ToString() )
                }
                "System.Byte[]" {
                    $bytes = $Data
                }
                "System.IO.FileInfo" {
                    $bytes = Get-Content -Path ($Data.FullName) -Encoding Byte
                }
                "System.String" {
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $Data )
                }
                "System.Management.Automation.PSCustomObject" {
                    $json = ConvertTo-Json -InputObject $Data -Depth 99
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $json )
                }
                default {
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $Data.ToString() )
                }
            }
        } elseif( $Text ) {
            $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $Text )
        } else {
            throw "Error, no input specified"
        }
        $fileData = [System.Convert]::ToBase64String( $bytes )
        $ex = $locker.Attachments | Where-Object { $_.FileName -eq $FileName }
        if( $ex ) {
            $ex.Data = $fileData
            $ex.Modified = (Get-Date).ToUniversalTime()
        } else {
            $ex = New-PowerPassAttachment
            $ex.FileName = $FileName
            $ex.Data = $fileData
            $locker.Attachments += $ex
        }
    } end {
        $pathToLocker = $script:PowerPass.LockerFilePath
        $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
        $data = Get-PowerPassLockerBytes -Locker $locker
        $aes = New-Object "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
        $aes.Encrypt( $data, $pathToLocker )
        $aes.Dispose()
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Add-PowerPassAttachment
# ------------------------------------------------------------------------------------------------------------- #

function Add-PowerPassAttachment {
    <#
        .SYNOPSIS
        Adds files from the file system into your locker.
        .PARAMETER FileInfo
        One or more FileInfo objects collected from Get-ChildItem.
        .PARAMETER FullPath
        If specified, the full file path will be saved as the file name. If the file already exists, it will be
        updated in your locker.
        .NOTES
        Rather than using Write-PowerPassAttachment, you can use Add-PowerPassAttachment to add multiple files
        to your locker at once by piping the output of Get-ChildItem to Add-PowerPassAttachment. Each file fetched
        by Get-ChildItem will be added to your locker using either the file name or the full path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $FileInfo,
        [switch]
        $FullPath
    )
    begin {
        $locker = Get-PowerPassLocker
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
    } process {
        $bytes = Get-Content -Path ($FileInfo.FullName) -Encoding Byte
        $fileData = [System.Convert]::ToBase64String( $bytes )
        $fileName = ""
        if( $FullPath ) {
            $fileName = $FileInfo.FullName
        } else {
            $fileName = $FileInfo.Name
        }
        $ex = $locker.Attachments | Where-Object { $_.FileName -eq $fileName }
        if( $ex ) {
            $ex.Data = $fileData
            $ex.Modified = (Get-Date).ToUniversalTime()
        } else {
            $ex = New-PowerPassAttachment
            $ex.FileName = $fileName
            $ex.Data = $fileData
            $locker.Attachments += $ex
        }
    } end {
        $pathToLocker = $script:PowerPass.LockerFilePath
        $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
        $data = Get-PowerPassLockerBytes -Locker $locker
        $aes = New-Object "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
        $aes.Encrypt( $data, $pathToLocker )
        $aes.Dispose()
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Remove-PowerPassAttachment
# ------------------------------------------------------------------------------------------------------------- #

function Remove-PowerPassAttachment {
    <#
        .SYNOPSIS
        Removes an attachment from your locker.
        .PARAMETER FileName
        The filename of the attachment to remove from your locker.
        .NOTES
        The filename  parameter can be passed from the pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $FileName
    )
    begin {
        $locker = Get-PowerPassLocker
        if( -not $locker ) {
            throw "Could not load your PowerPass locker"
        }
        $newLocker = New-PowerPassLocker
        # Old lockers do not have a Modified flag
        if( $locker.Modified ) {
            $newLocker.Modified = $locker.Modified
        }
        $newLocker.Created = $locker.Created
        $newLocker.Secrets = $locker.Secrets
        $changed = $false
    } process {
        foreach( $s in $locker.Attachments ) {
            if( ($s.FileName) -eq $FileName ) {
                $s.Mfd = $true
                $changed = $true
            }
        }
    } end {
        if( $changed ) {
            $newLocker.Attachments = $locker.Attachments | Where-Object { -not ($_.Mfd) }
            $pathToLocker = $script:PowerPass.LockerFilePath
            $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
            $data = Get-PowerPassLockerBytes $newLocker
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
    }
}