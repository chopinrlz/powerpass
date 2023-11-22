<#
    Root module for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Setup the constants for this module
$PowerPassEdition = "PowerPassV1"
$LockerFileName = "powerpass.locker"
$LockerSaltFileName = "locker.salt"
$KeePassLibraryFileName = "KeePassLib.dll"
$TestDatabaseFileName = "TestDatabase.kdbx"
$StatusLoggerSourceCode = "StatusLogger.cs"
$ExtensionsSourceCode = "Extensions.cs"
$ModuleSaltFileName = "powerpass.salt"

# Determine where user data should be stored
$UserDataPath = [System.Environment]::GetFolderPath("ApplicationData")
$UserDataFolderName = $PowerPassEdition

# Setup the root module object in script scope and load all relevant properties
$PowerPass = [PSCustomObject]@{
    KeePassLibraryPath = Join-Path -Path $PSScriptRoot -ChildPath $KeePassLibraryFileName
    KeePassLibAssembly = [System.Reflection.Assembly]$null
    TestDatabasePath   = Join-Path -Path $PSScriptRoot -ChildPath $TestDatabaseFileName
    StatusLoggerSource = Join-Path -Path $PSScriptRoot -ChildPath $StatusLoggerSourceCode
    ExtensionsSource   = Join-Path -Path $PSScriptRoot -ChildPath $ExtensionsSourceCode
    ModuleSaltFilePath = Join-Path -Path $PSScriptRoot -ChildPath $ModuleSaltFileName
    # These paths must always be a combination of the UserDataPath and the UserDataFolderName
    # The cmdlets in this module assume that the user data folder for PowerPass is $UserDataPath/$UserDataFolderName
    LockerFolderPath   = Join-Path -Path $UserDataPath -ChildPath "$UserDataFolderName"
    LockerFilePath     = Join-Path -Path $UserDataPath -ChildPath "$UserDataFolderName/$LockerFileName"
    LockerSaltPath     = Join-Path -Path $UserDataPath -ChildPath "$UserDataFolderName/$LockerSaltFileName"
    Implementation     = "DPAPI"
}

# Load the KeePassLib assembly from the module folder
$PowerPass.KeePassLibAssembly = [System.Reflection.Assembly]::LoadFrom( $PowerPass.KeePassLibraryPath )

# Load the System.Security assembly from the .NET Framework
[System.Reflection.Assembly]::LoadWithPartialName("System.Security")

# Compile and load the custom PowerPass.StatusLogger class
Add-Type -Path $PowerPass.StatusLoggerSource -ReferencedAssemblies $PowerPass.KeePassLibraryPath
Add-Type -Path $PowerPass.ExtensionsSource -ReferencedAssemblies $PowerPass.KeePassLibraryPath

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Open-PowerPassTestDatabase
# ------------------------------------------------------------------------------------------------------------- #

function Open-PowerPassTestDatabase {
    <#
        .SYNOPSIS
        Opens the TestDatabase.kdbx database bundled with PowerPass for testing.
        .DESCRIPTION
        When you use Open-PowerPassTestDatabase the PowerPass module will load the
        KeePass database TestDatabase.kdbx bundled with this module. By default,
        this database contains one key requried to open it: the password 12345. You
        can open this database in KeePass 2. It was originally created with KeePass 2.
        The output from this cmdlet includes all the relevant properties and data
        required to access and read data from KeePass databases. It also showcases
        the standard PSCustomObject data structure utilized by the PowerPass module.
        .INPUTS
        This cmdlet has no inputs, but it depends on the TestDatabase.kdbx file bundled
        with this module.
        .OUTPUTS
        This cmdlet outputs a PSCustomObject with these properties:
         1. Secrets - the KeePassLib.PwDatabase instance which exposes the secrets contained within the test database
         2. StatusLogger - the PowerPass.StatusLogger instance which captures logging messages from KeePassLib
         3. LiteralPath - the absolute path to the test database on the local file system
         4. Connector - the KeePassLib.IOConnectionInfo instance which tells KeePassLib where to find the test database
         5. Keys - the collection of keys required to open the test database, in this case just the password key
         .EXAMPLE
         $database = Open-PowerPassTestDatabase
         $rootGroup = $database.Secrets.RootGroup
         .NOTES
         This function will fail if the test database file is not found in the module folder.
    #>
    if ( -not (Test-Path $script:PowerPass.TestDatabasePath) ) {
        throw "Test database not found"
    }
    $database = [PSCustomObject]@{
        Secrets      = New-Object "KeePassLib.PwDatabase"
        StatusLogger = New-Object "PowerPass.StatusLogger"
        LiteralPath  = $script:PowerPass.TestDatabasePath
        Connector    = [KeePassLib.Serialization.IOConnectionInfo]::FromPath( $script:PowerPass.TestDatabasePath )
        Keys         = New-Object "KeePassLib.Keys.CompositeKey"
    }
    $database.StatusLogger.Echo = $true
    $passwordKey = New-Object -TypeName "KeePassLib.Keys.KcpPassword" -ArgumentList @('12345')
    $database.Keys.AddUserKey( $passwordKey )
    $database.Secrets.Open( $database.Connector, $database.Keys, $database.StatusLogger )
    Write-Output $database
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Open-PowerPassDatabase
# ------------------------------------------------------------------------------------------------------------- #

function Open-PowerPassDatabase {
    <#
        .SYNOPSIS
        Opens a PowerPass database from a KeePass file.
        .DESCRIPTION
        This cmdlet will open a KeePass database file from the given path using the keys specified by the given
        parameters. This cmdlet will then create a PSCustomObject containing the KeePass database in-memory
        along with the metadata about the database including its location on disk, log events from KeePass, and
        the collection of keys required to open it. You can then pipe or pass the output of this cmdlet to the
        Get-PowerPassSecret cmdlet to extract the encrypted secrets.
        .PARAMETER Path
        The path on disk to the KeePass file.
        .PARAMETER MasterPassword
        If the KeePass database uses a master password, include that here.
        .PARAMETER KeyFile
        If the KeePass database uses a key file, include the path to the key file here.
        .PARAMETER WindowsUserAccount
        If the KeePass database uses the Windows user account, include this switch.
        .INPUTS
        This cmdlet does not take any pipeline input.
        .OUTPUTS
        This cmdlet outputs a PowerPass object containing the KeePass database secrets. Pipe or pass this to
        Get-PowerPassSecret to extract the secrets from the database.
        .EXAMPLE
        #
        # This example shows how to open a KeePass database which uses a master password as a key
        # NOTE: This method is inherently insecure if you embed the password for the database into
        #       your PowerShell script itself. It is more secure to fetch a secure string from a
        #       separate location or use PowerPass to store this secret in your protected user
        #       profile directory, or in a separate KeePass database protected with your Windows
        #       user account.
        #

        $pw = ConvertTo-SecureString -String "databasePasswordHere" -AsPlainText -Force
        $db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -MasterPassword $pw

        #
        # This example shows how to open a KeePass database which uses a key file.
        # NOTE: You should always store the key file in a safe place like your user profile folder
        #       which can only be accessed by yourself and any local administrators on the computer.
        #

        $db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -KeyFile "C:\Users\me\Documents\DatabaseKeyFile.keyx"

        #
        # This example shows how to open a KeePass database which uses your Windows user account.
        # Securing a KeePass file with your Windows user account provides a very secure method for
        # storing secrets because they can only be accessed by you on the local machine and no one
        # else, not even local administrators or domain administrators. This method is recommended
        # for storing passwords to other KeePass databases.
        #

        $db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -WindowsUserAccount
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [SecureString]
        $MasterPassword,
        [string]
        $KeyFile,
        [switch]
        $WindowsUserAccount
    )
    if ( [String]::IsNullOrEmpty($Path) ) {
        throw "No Path specified"
    }
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if ( -not (Test-Path $fullPath) ) {
        throw "Database file not found at specified Path"
    }
    if ( -not $WindowsUserAccount ) {
        if ( -not($MasterPassword -or $KeyFile) ) {
            throw "At least one key must be specified"
        }
    }
    $database = [PSCustomObject]@{
        Secrets      = New-Object "KeePassLib.PwDatabase"
        StatusLogger = New-Object "PowerPass.StatusLogger"
        LiteralPath  = $fullPath
        Connector    = [KeePassLib.Serialization.IOConnectionInfo]::FromPath( $fullPath )
        Keys         = New-Object "KeePassLib.Keys.CompositeKey"
    }
    if ( $MasterPassword ) {
        $passwordKey = [PowerPass.Extensions]::CreateKcpPassword($MasterPassword)
        $database.Keys.AddUserKey( $passwordKey )
    }
    if ( $KeyFile ) {
        $keyFilePath = [System.IO.Path]::GetFullPath($KeyFile)
        if ( -not(Test-Path $keyFilePath) ) {
            throw "Could not locate key file"
        }
        $keyFileData = New-Object -TypeName "KeePassLib.Keys.KcpKeyFile" -ArgumentList @($keyFilePath)
        $database.Keys.AddUserKey( $keyFileData )
    }
    if ( $WindowsUserAccount ) {
        $userAccountKey = New-Object -TypeName "KeePassLib.Keys.KcpUserAccount"
        if ( $userAccountKey ) {
            $database.Keys.AddUserKey( $userAccountKey )
        } else {
            throw "Failed to generate user account key"
        }
    }
    $database.Secrets.Open( $database.Connector, $database.Keys, $database.StatusLogger )
    Write-Output $database
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassSecret {
    <#
        .SYNOPSIS
        Retrieves secrets from a PowerPass database.
        .DESCRIPTION
        This cmdlet will extract and decrypt the secrets stored in a PowerPass database which was opened using
        the Open-PowerPassDatabase cmdlet. An optional Match parameter can be specified to limit the secrets found
        to those which match the query, or which match the text exactly.
        .INPUTS
        This cmdlet will accept the output from Open-PowerPassDatabase as pipeline input.
        .OUTPUTS
        This cmdlet will output all, or each matching secret in the PowerPass database.
        .PARAMETER Database
        The PowerPass database opened using Open-PowerPassDatabase. This can be passed via pipeline.
        .PARAMETER Match
        An optional match filter. If this is specified, this cmdlet will only output secrets where the Title
        matches this filter. Use * for wildcards, use ? for single characters, or specify an exact Title for
        an exact match. If this is not specified, all secrets will be returned.
        .PARAMETER PlainTextPasswords
        An optional switch which will cause this cmdlet to output secrets with plain-text passwords. By default,
        passwords are returned as SecureString objects.
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [PSCustomObject]
        $Database,
        [string]
        $Match,
        [switch]
        $PlainTextPasswords
    )
    if ( -not $Database ) {
        throw "No database specified"
    }
    $secrets = $Database.Secrets
    if ( -not $secrets ) {
        throw "Database does not contain a Secrets property"
    }
    $rootGroup = $secrets.RootGroup
    if ( -not $rootGroup ) {
        throw "Secrets does not contain a RootGroup property"
    }
    if( $Match ) {
        if( $PlainTextPasswords ) {
            Search-PowerPassSecret -Group $rootGroup -Pattern $Match -PlainTextPasswords
        } else {
            Search-PowerPassSecret -Group $rootGroup -Pattern $Match
        }
    } else {
        if( $PlainTextPasswords ) {
            Search-PowerPassSecret -Group $rootGroup -Pattern "*" -PlainTextPasswords
        } else {
            Search-PowerPassSecret -Group $rootGroup -Pattern "*"
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Search-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Search-PowerPassSecret {
    <#
        .SYNOPSIS
        Recursively searches a KeePassLib.PwGroup for matching secrets.
        .DESCRIPTION
        This cmdlet is not exposed to end-users who install the module. It is used internally by PowerPass to
        perform a resursive search of a KeePass database for secrets which match the given pattern by Title.
        .PARAMETER Group
        The group to begin the search.
        .PARAMETER Pattern
        The search pattern.
        .PARAMETER PlainTextPasswords
        An optional switch to force the output of this cmdlet to include passwords in plain-text.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [KeePassLib.PwGroup]
        $Group,
        [Parameter(Mandatory = $true)]
        [string]
        $Pattern,
        [switch]
        $PlainTextPasswords
    )

    # Search all the entries in the current group
    foreach ( $entry in $Group.Entries ) {

        # Setup a temporary string for the Title value of the current entry
        $queryTitle = [String]::Empty

        # Search all the strings in the current entry
        foreach ( $entryProp in $entry.Strings ) {
            
            # Find the Title string and save its value
            if ( $entryProp.Key -eq "Title") {
                $queryTitle = $entryProp.Value.ReadString()
            }
        }

        # Check for a match to the entry we are searching for
        if ( $queryTitle -like $Pattern ) {

            # Create the Secret data object
            $Secret = [PSCustomObject]@{
                Title    = $queryTitle
                UserName = [String]::Empty
                Password = $null
                URL      = [String]::Empty
                Notes    = [String]::Empty
                Expires  = [System.DateTime]::Now
            }

            # Write all the properties into the object
            foreach ( $entryProp in $entry.Strings ) {
                switch ( $entryProp.Key ) {
                    "Title" {
                        $Secret.Title = $entryProp.Value.ReadString()
                    }
                    "UserName" {
                        $Secret.UserName = $entryProp.Value.ReadString()
                    }
                    "Password" {
                        if( $PlainTextPasswords ) {
                            $Secret.Password = $entryProp.Value.ReadString()
                        } else {
                            $secPw = ConvertTo-SecureString -String ($entryProp.Value.ReadString()) -AsPlainText -Force
                            $Secret.Password = $secPw
                        }
                    }
                    "URL" {
                        $Secret.URL = $entryProp.Value.ReadString()
                    }
                    "Notes" {
                        $Secret.Notes = $entryProp.Value.ReadString()
                    }
                }
            }

            # Check the expiration flag
            if( $entry.Expires ) {
                $Secret.Expires = $entry.ExpiryTime
            } else {
                $Secret.Expires = [DateTime]::MaxValue
            }

            # Write to the pipeline
            Write-Output $Secret
        }
    }

    # Search sub-groups if the entry is not found in the current group
    foreach ( $childGroup in $Group.Groups ) {
        if( $PlainTextPasswords ) {
            Search-PowerPassSecret -Group $childGroup -Pattern $Pattern -PlainTextPasswords
        } else {
            Search-PowerPassSecret -Group $childGroup -Pattern $Pattern
        }
    }
}

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
        if( Test-Path ($script:PowerPass.LockerSaltPath) ) {
            Remove-Item -Path ($script:PowerPass.LockerSaltPath) -Force
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
                if( Test-Path ($script:PowerPass.LockerSaltPath) ) {
                    Remove-Item -Path ($script:PowerPass.LockerSaltPath) -Force
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
    Initialize-PowerPassLockerSalt
    Initialize-PowerPassLocker
    $salt = Get-PowerPassLockerSalt
    if( -not $salt ) {
        throw "Failed to get locker, unable to get locker salt"
    }
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( Test-Path $pathToLocker ) {
        $encLockerString = Get-Content -Path $pathToLocker -Raw
        $encLockerBytes = [System.Convert]::FromBase64String($encLockerString)
        $lockerBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encLockerBytes,$salt,"CurrentUser")
        $lockerJson = [System.Text.Encoding]::UTF8.GetString($lockerBytes)
        $locker = ConvertFrom-Json $lockerJson
        Write-Output $locker
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
        $salt = Get-PowerPassLockerSalt
        if( -not $salt ) {
            throw "Error writing secret, no locker salt"
        }
        $pathToLocker = $script:PowerPass.LockerFilePath
        $json = $locker | ConvertTo-Json
        $data = [System.Text.Encoding]::UTF8.GetBytes($json)
        $encData = [System.Security.Cryptography.ProtectedData]::Protect($data,$salt,"CurrentUser")
        $encDataText = [System.Convert]::ToBase64String($encData)
        Out-File -FilePath $pathToLocker -InputObject $encDataText -Force
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
        An optional switch which instructs PowerPass to output the secrets as a PSCredential object. You cannot
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
# FUNCTION: Get-PowerPassSalt
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassSalt {
    <#
        .SYNOPSIS
        Gets the salt for this installation of PowerPass.
        .INPUTS
        This cmdlet does not take any input.
        .OUTPUTS
        This cmdlet outputs a byte array with the module salt for this PowerPass install. If no module salt file
        was found, this cmdlet outputs a $null to the pipeline.
    #>
    $pathToSalt = $script:PowerPass.ModuleSaltFilePath
    if( Test-Path $pathToSalt ) {
        $saltText = Get-Content -Path $pathToSalt -Raw
        $encSalt = [System.Convert]::FromBase64String($saltText)
        $salt = [System.Security.Cryptography.ProtectedData]::Unprotect($encSalt,$null,"LocalMachine")
        Write-Output $salt
    } else {
        Write-Output $null
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassLockerSalt
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassLockerSalt {
    <#
        .SYNOPSIS
        Gets the salt for the user's locker.
        .INPUTS
        This cmdlet does not take any input.
        .OUTPUTS
        This cmdlet outputs the byte array for the user's locker salt to the pipeline. If there is no locker
        salt file this cmdlet outputs $null to the pipeline.
    #>
    $moduleSalt = Get-PowerPassSalt
    if( -not $moduleSalt ) {
        throw "Your PowerPass installation does not have a module salt file"
    }
    $pathToSalt = $script:PowerPass.LockerSaltPath
    if( Test-Path $pathToSalt ) {
        $saltText = Get-Content -Path $pathToSalt -Raw
        $encSalt = [System.Convert]::FromBase64String($saltText)
        $salt = [System.Security.Cryptography.ProtectedData]::Unprotect($encSalt,$moduleSalt,"CurrentUser")
        Write-Output $salt
    } else {
        Write-Output $null
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Initialize-PowerPassLockerSalt
# ------------------------------------------------------------------------------------------------------------- #

function Initialize-PowerPassLockerSalt {
    <#
        .SYNOPSIS
        Generates a salt for the user's locker if it has not been generated already.
        .INPUTS
        This cmdlet does not take any input.
        .OUTPUTS
        This cmdlet does not output anything.
        .NOTES
        This cmdlet will break execution with a throw if either the PowerPass module is missing its module salt
        or if the locker salt file could not be written to the user data directory.
        .PARAMETER NoThrowOnOutFail
        Used internally, when specified will skip the final throw if Out-File fails to write the locker salt
        file to disk.
    #>
    param(
        [switch]
        $NoThrowOnOutFail
    )
    $moduleSalt = Get-PowerPassSalt
    if( -not $moduleSalt ) {
        throw "Your PowerPass installation does not have a module salt file"
    }
    Initialize-PowerPassUserDataFolder
    $pathToLockerSalt = $script:PowerPass.LockerSaltPath
    if( -not (Test-Path $pathToLockerSalt) ) {
        $saltShaker = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $lockerSalt = [System.Byte[]]::CreateInstance( [System.Byte], 32 )
        $saltShaker.GetBytes( $lockerSalt )
        $encLockerSalt = [System.Security.Cryptography.ProtectedData]::Protect($lockerSalt,$moduleSalt,"CurrentUser")
        $encLockerSaltText = [System.Convert]::ToBase64String($encLockerSalt)
        Out-File -InputObject $encLockerSaltText -FilePath $pathToLockerSalt -Force
    }
    if( -not (Test-Path $pathToLockerSalt) ) {
        if( $NoThrowOnOutFail ) {
            # Do not throw or block forward execution
        } else {
            throw "Cannot write to user data path to initialize salt file"
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
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( -not (Test-Path $pathToLocker) ) {
        $salt = Get-PowerPassLockerSalt
        if( -not $salt ) {
            throw "Failed to initialize the user's locker, unable to get the locker salt"
        }
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
        $encData = [System.Security.Cryptography.ProtectedData]::Protect($data,$salt,"CurrentUser")
        $encDataText = [System.Convert]::ToBase64String($encData)
        Out-File -FilePath $pathToLocker -InputObject $encDataText -Force
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
# FUNCTION: Update-PowerPassSalt
# ------------------------------------------------------------------------------------------------------------- #

function Update-PowerPassSalt {
    <#
        .SYNOPSIS
        Rotates the Locker salt to a new random key.
        .DESCRIPTION
        As a reoutine precaution, key rotation is recommended as a best practice when dealing with sensitive,
        encrypted data. When you rotate a key, PowerPass reencrypts your PowerPass Locker with a new Locker
        salt. This ensures that even if a previous encryption was broken, a new attempt must be made if an
        attacker regains access to your encrypted Locker.
    #>
    $moduleSalt = Get-PowerPassSalt
    if( -not $moduleSalt ) {
        throw "Unable to fetch the module salt"
    }
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Unable to fetch your PowerPass Locker"
    }
    $backupSalt = Get-PowerPassLockerSalt
    if( -not $backupSalt ) {
        throw "Unable to fetch backup of Locker salt"
    }
    Remove-Item -Path $script:PowerPass.LockerSaltPath -Force
    if( Test-Path $script:PowerPass.LockerSaltPath ) {
        throw "Could not delete Locker salt file"
    }
    Initialize-PowerPassLockerSalt -NoThrowOnOutFail
    $lockerSalt = Get-PowerPassLockerSalt
    if( -not $lockerSalt ) {
        $lockerSalt = $backupSalt
        $encLockerSalt = [System.Security.Cryptography.ProtectedData]::Protect($lockerSalt,$moduleSalt,"CurrentUser")
        $encLockerSaltText = [System.Convert]::ToBase64String($encLockerSalt)
        Out-File -InputObject $encLockerSaltText -FilePath ($script:PowerPass.LockerSaltPath) -Force
    }
    $json = $locker | ConvertTo-Json
    $data = [System.Text.Encoding]::UTF8.GetBytes($json)
    $encData = [System.Security.Cryptography.ProtectedData]::Protect($data,$lockerSalt,"CurrentUser")
    $encDataText = [System.Convert]::ToBase64String($encData)
    Out-File -FilePath ($script:PowerPass.LockerFilePath) -InputObject $encDataText -Force
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