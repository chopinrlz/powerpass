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
    TestDatabasePath = Join-Path -Path $PSScriptRoot -ChildPath "TestDatabase.kdbx"
    StatusLoggerSource = Join-Path -Path $PSScriptRoot -ChildPath "StatusLogger.cs"
}

# Load the KeePassLib assembly from the module folder
$PowerPass.KeePassLibAssembly = [System.Reflection.Assembly]::LoadFrom( $PowerPass.KeePassLibraryPath )

# Compile and load the custom PowerPass.StatusLogger class
Add-Type -Path $PowerPass.StatusLoggerSource -ReferencedAssemblies $PowerPass.KeePassLibraryPath

<#
    .SYNOPSIS
    Opens the TestDatabase.kdbx database bundled with PowerPass for testing.
#>
function Open-PowerPassTestDatabase {
    if( -not (Test-Path $script:PowerPass.TestDatabasePath) ) {
        throw "Test database not found"
    }
    $database = [PSCustomObject]@{
        Secrets = New-Object "KeePassLib.PwDatabase"
        StatusLogger = New-Object "PowerPass.StatusLogger"
        LiteralPath = $script:PowerPass.TestDatabasePath
        Connector = [KeePassLib.Serialization.IOConnectionInfo]::FromPath( $script:PowerPass.TestDatabasePath )
        Keys = New-Object "KeePassLib.Keys.CompositeKey"
    }
    $passwordKey = New-Object -TypeName "KeePassLib.Keys.KcpPassword" -ArgumentList @('12345')
    $database.Keys.AddUserKey( $passwordKey )
    $database.Secrets.Open( $database.Connector, $database.Keys, $database.StatusLogger )
    Write-Output $database
}