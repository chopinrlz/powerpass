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

function Clear-PowerPassLocker {
    $pathToLocker = $script:PowerPass.LockerFilePath
    if( Test-Path $pathToLocker ) {
        Remove-Item -Path $pathToLocker -Confirm        
        $pathToLockerSalt = $script:PowerPass.LockerSaltPath
        if( Test-Path $pathToLockerSalt ) {
            Remove-Item -Path $pathToLockerSalt -Force
        }
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassLocker
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassLocker {
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
# FUNCTION: Add-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Add-PowerPassSecret {
    param(
        [string]
        $Name,
        [string]
        $Secret
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Failed to initialize the PowerPass locker"
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Read-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Read-PowerPassSecret {
    param(
        [string]
        $Name,
        [switch]
        $Global
    )
    $locker = $null
    if( $Global ) {
        $locker = Get-PowerPassLocker -Global
    } else {
        $locker = Get-PowerPassLocker
    }
    if( -not $locker ) {
        Write-Output $null
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
        [byte[]]$encSalt = $saltText -split "," | ForEach-Object {
            [System.Convert]::ToByte( $_ )
        }
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
        [byte[]]$encSalt = $saltText -split "," | ForEach-Object {
            [System.Convert]::ToByte( $_ )
        }
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
    #>
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
        $encLockerSaltText = $encLockerSalt -join ","
        Out-File -InputObject $encLockerSaltText -FilePath $pathToLockerSalt -Force
    }
    if( -not (Test-Path $pathToLockerSalt) ) {
        throw "Cannot write to user data path to initialize salt file"
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
# FUNCTION: Initialize-PowerPassUserDataFolder
# ------------------------------------------------------------------------------------------------------------- #

function Initialize-PowerPassLocker {
    $salt = Get-PowerPassLockerSalt
    if( -not $salt ) {
        throw "Failed to initialize the user's locker, unable to get the locker salt"
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
        }
        $newAttachment = [PSCustomObject]@{
            FileName = "PowerPass.txt"
            Data = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("This is the default text file attachment."))
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