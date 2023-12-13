<#
    AES block cipher implementation of the PowerPass PowerShell module for PowerShell and Windows PowerShell
    Copyright 2023 by The Daltas Group LLC.
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
    CommonSourcePath    = Join-Path -Path $PSScriptRoot -ChildPath "PowerPass.Common.cs"
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
        $newSecret.URL = $URL
        $newSecret.Notes = $Notes
        $newSecret.Expires = $Expires
        $locker.Secrets += $newSecret
    }
    if( $changed ) {
        $pathToLocker = $script:PowerPass.LockerFilePath
        $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
        $json = ConvertTo-Json -InputObject $locker
        $data = [System.Text.Encoding]::UTF8.GetBytes($json)
        $aes = New-Object "PowerPass.AesCrypto"
        $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
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
        passwords are output as SecureString objects. You cannot combine this with AsCredential.
        .PARAMETER AsCredential
        An optional switch which instructs PowerPass to output the secrets as PSCredential objects. You cannot
        combine this with PlainTextPasswords.
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
        [Parameter(ValueFromPipeline,Position=0)]
        [string]
        $Match,
        [switch]
        $PlainTextPasswords,
        [switch]
        $AsCredential
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    } else {
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
        $locker = [PSCustomObject]@{
            Edition = $script:PowerPassEdition
            Created = (Get-Date).ToUniversalTime()
            Secrets = @()
            Attachments = @()
        }
        $newSecret = New-PowerPassSecret
        $newAttachment = [PSCustomObject]@{
            FileName = "PowerPass.txt"
            Data = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("This is the default text file attachment."))
            Created = [DateTime]::Now.ToUniversalTime()
            Modified = [DateTime]::Now.ToUniversalTime()
        }
        $locker.Attachments += $newAttachment
        $locker.Secrets += $newSecret
        $json = ConvertTo-Json -InputObject $locker
        $data = [System.Text.Encoding]::UTF8.GetBytes($json)
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
    $json = ConvertTo-Json -InputObject $locker
    $data = [System.Text.Encoding]::UTF8.GetBytes( $json )
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
    $json = ConvertTo-Json -InputObject $locker
    $data = [System.Text.Encoding]::UTF8.GetBytes($json)
    $aes.Encrypt( $data, $script:PowerPass.LockerFilePath )
    $aes.Dispose()
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: New-PowerPassRandomPassword
# ------------------------------------------------------------------------------------------------------------- #

function New-PowerPassRandomPassword {
    <#
        .SYNOPSIS
        Generates a random password from all available standard US 101-key keyboard characters.
        .PARAMETER Length
        The length of the password to generate. Can be between 1 and 65536 characters long. Defaults to 24.
        .OUTPUTS
        Outputs a random string of typable characters to the pipeline which can be used as a password.
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1,65536)]
        [int]
        $Length = 24
    )
    $bytes = [System.Byte[]]::CreateInstance( [System.Byte], $Length )
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes( $bytes )
    $bytes = $bytes | % { ( $_ % ( 126 - 33 ) ) + 33 }
    [System.Text.Encoding]::ASCII.GetString( $bytes )
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
# FUNCTION: Get-PowerPassCredential
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassCredential {
    <#
        .SYNOPSIS
        Converts a PowerPass secret into a PSCredential.
        .PARAMETER Secret
        The PowerPass secret.
    #>
    param(
        [PSCustomObject]
        $Secret
    )
    $x = @(($Secret.UserName), (ConvertTo-SecureString -String ($Secret.Password) -AsPlainText -Force))
    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $x
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
        $newLocker = [PSCustomObject]@{
            Edition = $locker.Edition
            Created = $locker.Created
            Secrets = @()
            Attachments = $locker.Attachments
        }
        $changed = $false
    } process {
        if( -not [String]::IsNullOrWhiteSpace( $Title ) ) {
            foreach( $s in $locker.Secrets ) {
                if( ($s.Title) -eq $Title ) {
                    $s.Mfd = $true
                    $changed = $true
                }
            }
        }
    } end {
        if( $changed ) {
            $newLocker.Secrets = $locker.Secrets | Where-Object { -not ($_.Mfd) }
            $pathToLocker = $script:PowerPass.LockerFilePath
            $pathToLockerKey = $script:PowerPass.LockerKeyFilePath
            $json = ConvertTo-Json -InputObject $newLocker
            $data = [System.Text.Encoding]::UTF8.GetBytes( $json )
            $aes = New-Object "PowerPass.AesCrypto"
            $aes.ReadKeyFromDisk( $pathToLockerKey, [ref] (Get-PowerPassEphemeralKey) )
            $aes.Encrypt( $data, $pathToLocker )
            $aes.Dispose()
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: New-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function New-PowerPassSecret {
    <#
        .SYNOPSIS
        Creates a new PowerPass secret with the standard properties and default values.
    #>
    [PSCustomObject]@{
        Title = "Default"
        UserName = "PowerPass"
        Password = "PowerPass"
        URL = "https://github.com/chopinrlz/powerpass"
        Notes = "This is the default secret for the PowerPass locker."
        Expires = [DateTime]::MaxValue
        Created = (Get-Date).ToUniversalTime()
        Modified = (Get-Date).ToUniversalTime()
        Mfd = $false
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