<#
    Root module for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Setup the root module object in script scope and load all relevant properties
$PowerPass = [PSCustomObject]@{
    KeePassLibraryPath = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
    KeePassLibAssembly = [System.Reflection.Assembly]$null
    TestDatabasePath   = Join-Path -Path $PSScriptRoot -ChildPath "TestDatabase.kdbx"
    StatusLoggerSource = Join-Path -Path $PSScriptRoot -ChildPath "StatusLogger.cs"
    ExtensionsSource   = Join-Path -Path $PSScriptRoot -ChildPath "Extensions.cs"
}

# Load the KeePassLib assembly from the module folder
$PowerPass.KeePassLibAssembly = [System.Reflection.Assembly]::LoadFrom( $PowerPass.KeePassLibraryPath )

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
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [PSCustomObject]
        $Database,
        [Parameter(Mandatory = $true)]
        [string]
        $Title
    )
    if ( -not $Database ) {
        throw "No database specified"
    }
    if ( [String]::IsNullOrEmpty($Title) ) {
        throw "No title specified"
    }
    $secrets = $Database.Secrets
    if ( -not $secrets ) {
        throw "Database does not contain a Secrets property"
    }
    $rootGroup = $secrets.RootGroup
    if ( -not $rootGroup ) {
        throw "Secrets does not contain a RootGroup property"
    }
    Search-PowerPassSecret -Group $rootGroup -Title $Title
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Search-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Search-PowerPassSecret {
    param(
        [KeePassLib.PwGroup]
        $Group,
        [string]
        $Title
    )

    # Declare the value to write out and test later
    $Secret = $null

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
        if ( [String]::Equals($Title, $queryTitle, "Ordinal") ) {

            # Create the Secret data object
            $Secret = [PSCustomObject]@{
                Title    = $queryTitle
                UserName = "UserName"
                Password = "Password"
                URL      = "URL"
                Notes    = "Notes"
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
                        $Secret.Password = $entryProp.Value.ReadString()
                    }
                }
            }

            # Write to the pipeline and stop searching
            Write-Output $Secret
            break
        }
    }

    # Search sub-groups if the entry is not found in the current group
    if ( -not $Secret ) {
        foreach ( $childGroup in $Group.Groups ) {
            $result = Search-PowerPassSecret -Group $childGroup -Title $Title
            if ( $result ) {
                Write-Output $result
                break
            }
        }
    }
}