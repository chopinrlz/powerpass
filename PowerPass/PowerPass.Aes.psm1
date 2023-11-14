<#
    Root module for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Setup the constants for this module
$PowerPassEdition = "powerpassv2"
$LockerFileName = "powerpass.locker"
$LockerKeyFileName = "locker.key"

# Determine where user data should be stored
$UserDataPath = [System.Environment]::GetFolderPath("ApplicationData")
$UserDataFolderName = $PowerPassEdition

# Setup the root module object in script scope and load all relevant properties
$PowerPass = [PSCustomObject]@{
    AesCryptoSourcePath = Join-Path -Path $PSScriptRoot -ChildPath "AesCrypto.cs"
    # These paths must always be a combination of the UserDataPath and the UserDataFolderName
    # The cmdlets in this module assume that the user data folder for PowerPass is $UserDataPath/$UserDataFolderName
    LockerFolderPath    = Join-Path -Path $UserDataPath -ChildPath "$UserDataFolderName"
    LockerFilePath      = Join-Path -Path $UserDataPath -ChildPath "$UserDataFolderName/$LockerFileName"
    LockerKeyPath       = Join-Path -Path $UserDataPath -ChildPath "$UserDataFolderName/$LockerKeyFileName"
}

# Compile and load the AesCrypto implementation
Add-Type -Path $PowerPass.AesCryptoSourcePath -ReferencedAssemblies "System.Security.Cryptography"

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Clear-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Clear-PowerPassLocker {
    <#
        .SYNOPSIS
        Deletes all your locker secrets.
        .DESCRIPTION
        If you want to delete your locker secrets and start with a clean locker, you can use thie cmdlet to do so.
        When you deploy PowerPass using the Deploy-Module.ps1 script provided with this module, it generates a
        unique salt for this deployment which is used to encrypt your locker's salt. If you replace this salt by
        redeploying the module, you will no longer be able to access your locker and will need to start with a
        clean locker.
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
        if( Test-Path ($script:PowerPass.LockerKeyPath) ) {
            Remove-Item -Path ($script:PowerPass.LockerKeyPath) -Force
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
                if( Test-Path ($script:PowerPass.LockerKeyPath) ) {
                    Remove-Item -Path ($script:PowerPass.LockerKeyPath) -Force
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
    $pathToLockerKey = $script:PowerPass.LockerKeyPath
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( Test-Path $pathToLocker ) {
        if( Test-Path $pathToLockerKey ) {
            $aes = New-Object -TypeName "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey )
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
        Writes a secret into your PowerPass locker.
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
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Title,
        [string]
        $UserName,
        [string]
        $Password,
        [string]
        $URL,
        [string]
        $Notes,
        [DateTime]
        $Expires = [DateTime]::MaxValue
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    $changed = $false
    $existingSecret = $locker.Secrets | Where-Object { 'Title' -eq $Title }
    if( $existingSecret ) {
        if( $UserName ) {
            $existingSecret.UserName = $UserName
            $changed = $true
        }
        if( $Password ) {
            $existingSecret.Password = $Password
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
        $newSecret = [PSCustomObject]@{
            Title = $Title
            UserName = $UserName
            Password = $Password
            URL = $URL
            Notes = $Notes
            Expires = $Expires
            Created = (Get-Date).ToUniversalTime()
            Modified = (Get-Date).ToUniversalTime()
        }
        $locker.Secrets += $newSecret
    }
    if( $changed ) {
        $pathToLocker = $script:PowerPass.LockerFilePath
        $pathToLockerKey = $script:PowerPass.LockerKeyPath
        $json = $locker | ConvertTo-Json
        $data = [System.Text.Encoding]::UTF8.GetBytes($json)
        $aes = New-Object "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $pathToLockerKey )
        $aes.Encrypt( $data, $pathToLocker )
        $aes.Dispose()
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Set-PowerPassSecureString
# ------------------------------------------------------------------------------------------------------------- #

function Set-PowerPassSecureString {
    <#
        .SYNOPSIS
        Converts a PowerPass secret's password into a SecureString and writes the secret to the pipeline.
        .PARAMETER Secret
        The PowerPass secret. This will be output to the pipeline once the password is converted.
        .INPUTS
        This cmdlet takes PowerPass secrets as input.
        .OUTPUTS
        This cmdlet writes the PowerPass secret to the pipeline after converting the password to a SecureString.
    #>
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline,Position=0)]
        $Secret
    )
    begin {
        # Start work on collection of secrets
    } process {
        if( $Secret.Password ) {
            $Secret.Password = ConvertTo-SecureString -String ($Secret.Password) -AsPlainText -Force
        }
        Write-Output $Secret
    } end {
        # Complete work on collection of secrets
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
        .PARAMETER PlainTextPasswords
        An optional switch which instructs PowerPass to output the passwords in plain-text. By default, all
        passwords are output as SecureString objects.
        .INPUTS
        This cmdlet takes no input.
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
        [string]
        $Match,
        [switch]
        $PlainTextPasswords
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    } else {
        if( $Match ) {
            if( $PlainTextPasswords ) {
                $locker.Secrets | Where-Object { $_.Title -like $Match } | Write-Output
            } else {
                $locker.Secrets | Where-Object { $_.Title -like $Match } | Set-PowerPassSecureString
            }
        } else {
            if( $PlainTextPasswords ) {
                Write-Output $locker.Secrets
            } else {
                $locker.Secrets | Set-PowerPassSecureString
            }
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
    if( -not (Test-Path ($script:PowerPass.LockerFolderPath) ) ) {
        New-Item -Path $script:UserDataPath -Name $script:UserDataFolderName -ItemType Directory | Out-Null
        if( -not (Test-Path ($script:PowerPass.LockerFolderPath)) ) {
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
    $pathToLockerKey = $script:PowerPass.LockerKeyPath
    if( -not (Test-Path $pathToLockerKey) ) {
        $aes = New-Object -TypeName "PowerPass.AesCrypto"
        $aes.GenerateKey()
        $aes.WriteKeyToDisk( $pathToLockerKey )
        $aes.Dispose()
        $aes = $null
    }
    if( -not (Test-Path $pathToLockerKey) ) {
        throw "Cannot write to user data path to initialize key file"
    }
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( -not (Test-Path $pathToLocker) ) {
        $locker = [PSCustomObject]@{
            Edition = $script:PowerPassEdition
            Created = (Get-Date).ToUniversalTime()
            Secrets = @()
            Attachments = @()
        }
        $newSecret = [PSCustomObject]@{
            Title = "Default"
            UserName = "PowerPass"
            Password = "PowerPass"
            URL = "https://github.com/chopinrlz/powerpass"
            Notes = "This is the default secret for the PowerPass locker."
            Expires = [DateTime]::MaxValue
            Created = [DateTime]::Now.ToUniversalTime()
            Modified = [DateTime]::Now.ToUniversalTime()
        }
        $newAttachment = [PSCustomObject]@{
            FileName = "PowerPass.txt"
            Data = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("This is the default text file attachment."))
            Created = [DateTime]::Now.ToUniversalTime()
            Modified = [DateTime]::Now.ToUniversalTime()
        }
        $locker.Attachments += $newAttachment
        $locker.Secrets += $newSecret
        $json = $locker | ConvertTo-Json
        $data = [System.Text.Encoding]::UTF8.GetBytes($json)
        $aes = New-Object -TypeName "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $pathToLockerKey )
        $aes.Encrypt( $data, $pathToLocker )
        $aes.Dispose()
        $aes = $null
    }
    if( -not (Test-Path $pathToLocker) ) {
        throw "Failed to initialize the user's locker"
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Test-PowerPassAnswer
# ------------------------------------------------------------------------------------------------------------- #

function Test-PowerPassAnswer {
    <#
        .SYNOPSIS
        Tests an answer prompt from the user for a yes.
        .PARAMETER Answer
        The text reply from the user on the console.
        .INPUTS
        This cmdlet takes a string for input.
        .OUTPUTS
        This cmdlet outputs $true only if the string equals 'y' or 'Y', otherwise $false.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $Answer
    )
    if( $Answer ) {
        if( ($Answer -eq 'y') -or ($Answer -eq 'Y') ) {
            Write-Output $true
        } else {
            Write-Output $false
        }
    } else {
        Write-Output $false
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Export-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Export-PowerPassLocker {
    <#
        .SYNOPSIS
        Exports your PowerPass Locker file, Locker salt file, and module salt file.
        .PARAMETER Path
        The path where the exported files will go. This is mandatory, and this path must exist.
        .PARAMETER LockerFileName
        An optional name for your Locker file.
        .PARAMETER LockerSaltFileName
        An optional name for your Locker salt file.
        .PARAMETER ModuleSaltFileName
        An optional name for your module salt file.
        .OUTPUTS
        This cmdlet does not output to the pipeline, it copies three files to the specified Path.
        1. powerpass.salt
        2. locker.salt
        3. powerpass.locker
        .DESCRIPTION
        You can export a PowerPass locker including the locker file, locker salt and module salt.
        Lockers only work on the same computer under the same user profile since they are encrypted
        with the Data Protection API under the current user scope. This means you cannot import a
        Locker exported from another machine or from a different user profile. You should export your
        Locker before you install a new version of PowerPass, or to back up your Locker in case you
        lose your AppData folder or you redeploy PowerPass.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $Path,
        [string]
        $LockerFileName,
        [string]
        $LockerSaltFileName,
        [string]
        $ModuleSaltFileName
    )
    if( -not (Test-Path $Path) ) {
        throw "$Path does not exist"
    }
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Unable to initialize your locker"
    }
    if( -not (Test-Path ($PowerPass.ModuleSaltFilePath)) ) {
        throw "Illegal or undefined module salt file path"
    }
    if( -not (Test-Path ($PowerPass.LockerSaltPath)) ) {
        throw "Illegal or undefined locker salt file path"
    }
    if( $ModuleSaltFileName ) {
        $target = Join-Path -Path $Path -ChildPath $ModuleSaltFileName
        Copy-Item -Path $PowerPass.ModuleSaltFilePath -Destination $target
    } else {
        Copy-Item -Path $PowerPass.ModuleSaltFilePath -Destination $Path
    }
    if( $LockerSaltFileName ) {
        $target = Join-Path -Path $Path -ChildPath $LockerSaltFileName
        Copy-Item -Path $PowerPass.LockerSaltPath -Destination $target
    } else {
        Copy-Item -Path $PowerPass.LockerSaltPath -Destination $Path
    }
    if( $LockerFileName ) {
        $target = Join-Path -Path $Path -ChildPath $LockerFileName
        Copy-Item -Path $PowerPass.LockerFilePath -Destination $target
    } else {
        Copy-Item -Path $PowerPass.LockerFilePath -Destination $Path
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Import-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Import-PowerPassLocker {
    <#
        .SYNOPSIS
        Imports a PowerPass locker with salt files from a previous export.
        .PARAMETER LockerFilePath
        The path to the locker file on disk. This is mandatory.
        .PARAMETER LockerSaltPath
        The path fo the locker salt file on disk. This is mandatory.
        .PARAMETER ModuleSaltPath
        The optional path to the module salt, if you also want to restore your module salt.
        .DESCRIPTION
        You can import a PowerPass locker including the locker salt and module salt from an exported
        copy. Lockers will only work on the same computer under the same user profile since they are
        encrypted with the Data Protection API under the current user scope. This means you cannot
        import a Locker from one machine to another or from one user to another. The most useful
        scenario for importing your Locker back into PowerPass is if you deploy a new version
        and want to restore your Locker secrets, or you accidentally lose your Locker secrets for
        example of they are removed up from your AppData folder or the PowerPass module is removed
        from your computer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $LockerFilePath,
        [Parameter(Mandatory)]
        [string]
        $LockerSaltPath,
        [string]
        $ModuleSaltPath
    )
    if( -not (Test-Path $LockerFilePath) ) {
        throw "Locker file path does not exist"
    }
    if( -not (Test-Path $LockerSaltPath) ) {
        throw "Locker salt file path does not exist"
    }
    if( $ModuleSaltPath ) {    
        if( -not (Test-Path $ModuleSaltPath) ) {
            throw "Module salt file path does not exist"
        }
    }
    Write-Warning "You are about to OVERWRITE your existing locker. This will REPLACE ALL existing locker secrets."
    $answer = Read-Host "Do you you want to continue? [N/y]"
    if( Test-PowerPassAnswer $answer ) {
        Copy-Item -Path $LockerFilePath -Destination ($PowerPass.LockerFilePath) -Force
        Copy-Item -Path $LockerSaltPath -Destination ($PowerPass.LockerSaltPath) -Force
    } else {
        throw "Import cancelled by user"
    }
    if( $ModuleSaltPath ) {
        Write-Warning "You are about to OVERWRITE your PowerPass module salt. This will INVALIDATE ALL existing locker secrets."
        $answer = Read-Host "Do you you want to continue? [N/y]"
        if( Test-PowerPassAnswer $answer ) {
            Copy-Item -Path $ModuleSaltPath -Destination ($PowerPass.ModuleSaltFilePath) -Force
        } else {
            throw "Import cancelled by user"
        }
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
        encrypted data. When you rotate a key, PowerPass reencrypts your PowerPass Locker with a new Locker
        salt. This ensures that even if a previous encryption was broken, a new attempt must be made if an
        attacker regains access to your encrypted Locker.
    #>
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Unable to fetch your PowerPass Locker"
    }
    Remove-Item -Path $script:PowerPass.LockerKeyPath -Force
    if( Test-Path $script:PowerPass.LockerKeyPath ) {
        throw "Could not delete Locker key file"
    }
    $aes = New-Object -TypeName "PowerPass.AesCrypto"
    $aes.GenerateKey()
    $aes.WriteKeyToDisk( $script:PowerPass.LockerKeyPath )
    $json = $locker | ConvertTo-Json
    $data = [System.Text.Encoding]::UTF8.GetBytes($json)
    $aes.Encrypt( $data, $script:PowerPass.LockerFilePath )
    $aes.Dispose()
}