<#
    AES block cipher implementation of the PowerPass PowerShell module for PowerShell and Windows PowerShell
    Copyright 2023-2025 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Setup basic variables for this module
$PowerPassEdition = "powerpassv2"
$LockerFileName = ".powerpass_locker"
$LockerKeyFileName = ".locker_key"
$CustomSettingsFileName = ".powerpass_settings"

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
    CompressorPath      = Join-Path -Path $PSScriptRoot -ChildPath "Compression.cs"
    ConversionPath      = Join-Path -Path $PSScriptRoot -ChildPath "Conversion.cs"
    LockerFolderPath    = $UserDataPath
    LockerFilePath      = Join-Path -Path $UserDataPath -ChildPath $LockerFileName
    LockerKeyFolderPath = Join-Path -Path $AppDataPath -ChildPath $PowerPassEdition
    LockerKeyFilePath   = Join-Path -Path $AppDataPath -ChildPath "$PowerPassEdition/$LockerKeyFileName"
    Implementation      = "AES"
    Version             = (Import-PowerShellDataFile -Path "$PSScriptRoot/PowerPass.psd1").ModuleVersion
    CustomSettingsFile  = Join-Path -Path $UserDataPath -ChildPath $CustomSettingsFileName
}

# Test for custom settings
if( Test-Path ($PowerPass.CustomSettingsFile) ) {
    $customSettings = ConvertFrom-Json (Get-Content ($PowerPass.CustomSettingsFile) -Raw)
    if( $customSettings ) {
        $script:LockerFileName = ($customSettings.LockerFileName)
        $script:LockerKeyFileName = ($customSettings.LockerKeyFileName)
        $script:PowerPass.LockerFolderPath = ($customSettings.LockerFolderPath)
        $script:PowerPass.LockerFilePath = Join-Path -Path ($customSettings.LockerFolderPath) -ChildPath ($customSettings.LockerFileName)
        $script:PowerPass.LockerKeyFolderPath = ($customSettings.LockerKeyFolderPath)
        $script:PowerPass.LockerKeyFilePath = Join-Path -Path ($customSettings.LockerKeyFolderPath) -ChildPath ($customSettings.LockerKeyFileName)
    }
}

# Compile and load the AesCrypto implementation
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    Add-Type -Path $PowerPass.AesCryptoSourcePath -ReferencedAssemblies "System.Security"
} else {
    Add-Type -Path $PowerPass.AesCryptoSourcePath -ReferencedAssemblies "System.Security.Cryptography","System.Collections"
}

# Compile and load the GZip implementation
Add-Type -Path $PowerPass.CompressorPath

# Compile and load the base64 conversion replacement cmdlets to circumvent AMSI
Add-Type -Path $PowerPass.ConversionPath -PassThru | ForEach-Object { Import-Module ($_.Assembly) }

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
    param(
        [Parameter(Mandatory)]
        [ref]
        $Locker
    )
    Initialize-PowerPassLocker
    $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( Test-Path $pathToLocker ) {
        if( Test-Path $pathToLockerKey ) {
            $aes = New-Object -TypeName "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $lockerBytes = $aes.Decrypt( $pathToLocker )
            if( -not $lockerBytes ) {
                throw "Decryption failed for [$pathToLocker]"
            }
            $lockerJson = [System.Text.Encoding]::UTF8.GetString( $lockerBytes )
            [PowerPass.AesCrypto]::EraseBuffer( $lockerBytes )
            $openLocker = ConvertFrom-Json $lockerJson
            if( -not $openLocker ) {
                throw "Invalid data format for [$pathToLocker]"
            }
            if( -not $openLocker.Revision ) {
                Write-Warning "Your Locker has not been upgraded"
            }
            $Locker.Value = $openLocker
            $aes.Dispose()
            $aes = $null
            $lockerBytes = $null
            $lockerJson = $null
        } else {
            $Locker.Value = $null
        }
    } else {
        $Locker.Value = $null
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
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        $changed = $false
    } process {
        $existingSecret = $locker.Secrets | Where-Object { $_.Title -eq $Title }
        if( $existingSecret ) {
            Unlock-PowerPassSecret $existingSecret
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
                Lock-PowerPassSecret $existingSecret
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
            Lock-PowerPassSecret $newSecret
            $locker.Secrets += $newSecret
        }
    } end {
        if( $changed ) {
            $pathToLocker = $script:PowerPass.LockerFilePath
            $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
            [byte[]]$data = $null
            Get-PowerPassLockerBytes -Locker $locker -Data ([ref] $data)
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
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
    if( -not (Test-Path ($PowerPass.LockerFolderPath) ) ) {
        throw "Your locker folder path does not exist"
    }
    if( -not (Test-Path ($PowerPass.LockerKeyFolderPath) ) ) {
        $null = New-Item -Path $PowerPass.LockerKeyFolderPath -ItemType Directory
        if( -not (Test-Path ($PowerPass.LockerKeyFolderPath)) ) {
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
        [byte[]]$data = $null
        Get-PowerPassLockerBytes -Locker $locker -Data ([ref] $data)
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

    # Assert the provided path location
    if( -not (Test-Path $Path) ) {
        throw "$Path does not exist"
    }

    # Open the locker
    [PSCustomObject]$locker = $null
    Get-PowerPassLocker -Locker ([ref] $locker)
    if( -not $locker ) {
        throw "Could not load you PowerPass locker"
    }

    # Prompt for a password to encrypt the locker
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

    # Generate the output filename for the export and test for overwrite
    $output = Join-Path -Path $Path -ChildPath "powerpass_locker.bin"
    if( Test-Path $output ) {
        $answer = Read-Host "$output already exists, overwrite? [N/y]"
        if( Test-PowerPassAnswer $answer ) {
            Remove-Item -Path $output
        } else {
            throw "Export cancelled by user"
        }
    }

    # Unlock all the secrets in the locker for export
    if( $locker.Secrets ) {
        $locker.Secrets | Unlock-PowerPassSecret
    }

    # Export the encrypted locker data to disk
    [byte[]]$data = $null
    Get-PowerPassLockerBytes -Locker $locker -Data ([ref] $data)
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
        .PARAMETER Merge
        Merge the contents of the Locker file backup with your existing Locker.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $LockerFile,
        [switch]
        $Force,
        [switch]
        $Merge
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
        throw "Decryption failed for [$LockerFile]"
    }

    # Check for existing locker
    if( Test-Path ($PowerPass.LockerFilePath) ) {
        $warn = if( $Force ) { $false } else { $true }
    } else {
        Initialize-PowerPassLocker
        $warn = $false
    }

    # Determine the import routine
    if( $Merge ) {

        # Parse the imported data into object format for parsing
        $lockerJson = ConvertTo-Utf8String -InputObject $data
        $from = ConvertFrom-Json $lockerJson
        if( -not $from ) {
            throw "Invalid data format for [$LockerFile]"
        }
        [PowerPass.AesCrypto]::EraseBuffer( $data )

        # Import the current locker
        $modified = $false
        [PSCustomObject]$to = $null
        Get-PowerPassLocker -Locker ([ref] $to)
        foreach( $secret in $from.Secrets ) {
            $existing = $to.Secrets | Where-Object { $_.Title -eq ($secret.Title) }
            if( $existing ) {
                $existing.UserName = $secret.UserName
                $existing.Password = $secret.Password
                $existing.URL = $secret.URL
                $existing.Notes = $secret.Notes
                $existing.Expires = $secret.Expires
                $existing.Modified = (Get-Date).ToUniversalTime()
                Lock-PowerPassSecret $existing
                $modified = $true
            } else {
                Lock-PowerPassSecret $secret
                $to.Secrets += $secret
                $modified = $true
            }
        }

        # Write out the new Locker file
        if( $modified ) {
            $pathToLocker = $PowerPass.LockerFilePath
            $pathToLockerKey = $PowerPass.LockerKeyFilePath
            [byte[]]$newData = $null
            Get-PowerPassLockerBytes -Locker $to -Data ([ref] $newData)
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $newData, $pathToLocker )
            $aes.Dispose()
            [PowerPass.AesCrypto]::EraseBuffer( $newData )
        }
    } else {

        # Check for warning message
        if( $warn ) {
            $answer = Read-Host "You are about to overwrite your existing locker. Proceed? [N/y]"
            if( Test-PowerPassAnswer $answer ) { 
                Write-Output "Restoring locker from $LockerFile"
            } else {
                throw "Import cancelled by user"
            }
        }

        # Lock the imported locker
        $lockerJson = [System.Text.Encoding]::UTF8.GetString( $data )
        $openLocker = ConvertFrom-Json $lockerJson
        if( -not $openLocker ) {
            throw "Invalid data format for [$pathToLocker]"
        }
        if( $openLocker.Secrets ) {
            $openLocker.Secrets | Lock-PowerPassSecret
        }
        [PowerPass.AesCrypto]::EraseBuffer( $data )
        Get-PowerPassLockerBytes -Locker $openLocker -Data ([ref] $data)

        # Save the imported locker
        $aes = New-Object "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $PowerPass.LockerKeyFilePath, [ref] (Get-PowerPassEphemeralKey) )
        $aes.Encrypt( $data, $PowerPass.LockerFilePath )
        $aes.Dispose()
        [PowerPass.AesCrypto]::EraseBuffer( $data )
    }
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
    [PSCustomObject]$locker = $null
    Get-PowerPassLocker -Locker ([ref] $locker)
    if( -not $locker ) {
        throw "Unable to fetch your PowerPass Locker"
    }
    Remove-Item -Path $PowerPass.LockerKeyFilePath -Force
    if( Test-Path $PowerPass.LockerKeyFilePath ) {
        throw "Could not delete Locker key file"
    }
    $aes = New-Object -TypeName "PowerPass.AesCrypto"
    $aes.GenerateKey()
    $aes.WriteKeyToDisk( $PowerPass.LockerKeyFilePath, [ref] (Get-PowerPassEphemeralKey) )
    [byte[]]$data = $null
    Get-PowerPassLockerBytes -Locker $locker -Data ([ref] $data)
    $aes.Encrypt( $data, $PowerPass.LockerFilePath )
    $aes.Dispose()
    [PowerPass.AesCrypto]::EraseBuffer( $data )
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
# FUNCTION: Set-PowerPass
# ------------------------------------------------------------------------------------------------------------- #

function Set-PowerPass {
    <#
        .SYNOPSIS
        Sets custom parameters for your PowerPass setup.
        .PARAMETER NewLockerFolderPath
        Set an alternate path for your Locker file.
        .PARAMETER NewLockerFileName
        Set an alternate file name for your Locker.
        .PARAMETER NewLockerKeyFolderPath
        Set an alternate path for your Locker's key file.
        .PARAMETER NewLockerKeyFileName
        Set an alternate file name for your Locker's key.
        .PARAMETER Reset
        Resets all settings to their default values. Cannot be combined with other parameters.
    #>
    param(
        [Parameter(ParameterSetName="New")]
        [string]
        $NewLockerFolderPath,
        [Parameter(ParameterSetName="New")]
        [string]
        $NewLockerFileName,
        [Parameter(ParameterSetName="New")]
        [string]
        $NewLockerKeyFolderPath,
        [Parameter(ParameterSetName="New")]
        [string]
        $NewLockerKeyFileName,
        [Parameter(ParameterSetName="Reset")]
        [switch]
        $Reset
    )
    if( $Reset ) {
        if( Test-Path ($PowerPass.CustomSettingsFile) ) {
            Remove-Item -Path ($PowerPass.CustomSettingsFile)
            if( Test-Path ($PowerPass.CustomSettingsFile) ) {
                Write-Warning "Could not remove custom settings file $($PowerPass.CustomSettingsFile)"
            }
        }
        $script:LockerFileName = ".powerpass_locker"
        $script:LockerKeyFileName = ".locker_key"
        $script:PowerPass.LockerFolderPath = $UserDataPath
        $script:PowerPass.LockerFilePath = Join-Path -Path $UserDataPath -ChildPath $LockerFileName
        $script:PowerPass.LockerKeyFolderPath = Join-Path -Path $AppDataPath -ChildPath $PowerPassEdition
        $script:PowerPass.LockerKeyFilePath = Join-Path -Path $AppDataPath -ChildPath "$PowerPassEdition/$LockerKeyFileName"
    } else {
        $customSettings = [PSCustomObject]@{
            LockerFolderPath = $PowerPass.LockerFolderPath
            LockerFileName = $LockerFileName
            LockerKeyFolderPath = $PowerPass.LockerKeyFolderPath
            LockerKeyFileName = $LockerKeyFileName
        }
        if( Test-Path ($PowerPass.CustomSettingsFile) ) {
            $customSettings = ConvertFrom-Json (Get-Content ($PowerPass.CustomSettingsFile) -Raw)
        } else {
            ConvertTo-Json -InputObject $customSettings | Out-File -FilePath ($PowerPass.CustomSettingsFile)
        }
        if( -not (Test-Path ($PowerPass.CustomSettingsFile)) ) {
            throw "Cannot write settings file $($PowerPass.CustomSettingsFile)"
        }
        if( $NewLockerFolderPath ) {
            $customSettings.LockerFolderPath = $NewLockerFolderPath
        }
        if( $NewLockerFileName ) {
            $customSettings.LockerFileName = $NewLockerFileName
        }
        if( $NewLockerKeyFolderPath ) {
            $customSettings.LockerKeyFolderPath = $NewLockerKeyFolderPath
        }
        if( $NewLockerKeyFileName ) {
            $customSettings.LockerKeyFileName = $NewLockerKeyFileName
        }
        $script:PowerPass.LockerFolderPath = ($customSettings.LockerFolderPath)
        $script:PowerPass.LockerFilePath = [System.IO.Path]::Combine( ($customSettings.LockerFolderPath), ($customSettings.LockerFileName) )
        $script:PowerPass.LockerKeyFolderPath = ($customSettings.LockerKeyFolderPath)
        $script:PowerPass.LockerKeyFilePath = [System.IO.Path]::Combine( ($customSettings.LockerKeyFolderPath), ($customSettings.LockerKeyFileName) )
        Remove-Item -Path ($PowerPass.CustomSettingsFile)
        ConvertTo-Json -InputObject $customSettings | Out-File -FilePath ($PowerPass.CustomSettingsFile)
    }
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
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
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
            [byte[]]$data = $null
            Get-PowerPassLockerBytes -Locker $newLocker -Data ([ref] $data)
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
    }
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
        .PARAMETER GZip
        An optional parameter to compress the attachment using GZip before storing it.
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
        $Text,
        [Parameter(ParameterSetName="FromDisk")]
        [Parameter(ParameterSetName="FromDiskLiteral")]
        [Parameter(ParameterSetName="FromPipeline")]
        [switch]
        $GZip
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        if( $locker.Attachments.Length -le 0 ) {
            $locker.Attachments = @()
        }
    } process {
        [byte[]]$bytes = $null
        $setGZipFlag = $false
        if( $Path ) {
            $fileInfo = Get-Item -Path $Path
            if( $GZip ) {
                $bytes = [PowerPass.Compressor]::CompressFromDisk( $fileInfo.FullName )
                $setGZipFlag = $true
            } else {
                $bytes = [System.IO.File]::ReadAllBytes( $fileInfo.FullName )
            }
        } elseif( $LiteralPath ) {
            $fileInfo = Get-Item -LiteralPath $LiteralPath
            if( $GZip ) {
                $bytes = [PowerPass.Compressor]::CompressFromDisk( $fileInfo.FullName )
                $setGZipFlag = $true
            } else {
                $bytes = [System.IO.File]::ReadAllBytes( $fileInfo.FullName )
            }
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
                    if( $GZip ) {
                        $bytes = [PowerPass.Compression]::CompressFromDisk( $Data.FullName )
                        $setGZipFlag = $true
                    } else {
                        $bytes = [System.IO.File]::ReadAllBytes( $Data.FullName )
                    }
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
        $fileData = ConvertTo-Base64String -InputObject $bytes
        $ex = $locker.Attachments | Where-Object { $_.FileName -eq $FileName }
        if( $ex ) {
            $ex.Data = $fileData
            $ex.Modified = (Get-Date).ToUniversalTime()
            if( -not (Get-Member -InputObject $ex -Name "GZip") ) {
                Add-Member -InputObject $ex -Name "GZip" -Value $false
            }
            $ex.GZip = $setGZipFlag
        } else {
            $ex = New-PowerPassAttachment
            $ex.FileName = $FileName
            $ex.Data = $fileData
            $ex.GZip = $setGZipFlag
            $locker.Attachments += $ex
        }
    } end {
        $pathToLocker = $script:PowerPass.LockerFilePath
        $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
        [byte[]]$data = $null
        Get-PowerPassLockerBytes -Locker $locker -Data ([ref] $data)
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
        .PARAMETER GZip
        Enable GZip compression.
        .NOTES
        Rather than using Write-PowerPassAttachment, you can use Add-PowerPassAttachment to add multiple files
        to your locker at once by piping the output of Get-ChildItem to Add-PowerPassAttachment. Each file fetched
        by Get-ChildItem will be added to your locker using either the file name or the full path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        $FileInfo,
        [switch]
        $FullPath,
        [switch]
        $GZip
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        $changed = $false
        if( $locker.Attachments.Length -le 0 ) {
            $locker.Attachments = @()
        }
    } process {
        if( $FileInfo.GetType().FullName -eq "System.IO.FileInfo" ) {
            $changed = $true
            [byte[]]$bytes = $null
            if( $GZip ) {
                $bytes = [PowerPass.Compressor]::CompressFromDisk( $FileInfo.FullName )
            } else {
                $bytes = [System.IO.File]::ReadAllBytes( $FileInfo.FullName )
            }
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
                if( -not (Get-Member -InputObject $ex -Name "GZip") ) {
                    Add-Member -InputObject $ex -Name "GZip" -Value $false
                }
                if( $GZip ) {
                    $ex.GZip = $true
                } else {
                    $ex.GZip = $false
                }
            } else {
                $ex = New-PowerPassAttachment
                $ex.FileName = $fileName
                $ex.Data = $fileData
                if( $GZip ) {
                    $ex.GZip = $true
                } else {
                    $ex.GZip = $false
                }
                $locker.Attachments += $ex
            }
        }
    } end {
        if( $changed ) {
            $pathToLocker = $script:PowerPass.LockerFilePath
            $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
            [byte[]]$data = $null
            Get-PowerPassLockerBytes -Locker $locker -Data ([ref] $data)
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
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
        The filename parameter can be passed from the pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $FileName
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
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
            [byte[]]$data = $null
            Get-PowerPassLockerBytes -Locker $newLocker -Data ([ref] $data)
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
    }
}