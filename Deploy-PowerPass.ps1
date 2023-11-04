<#
    Compilation and deployment script for PowerPass
    Copyright 2023 by The Daltas Group LLC.
    The KeePassLib source code is copyright (C) 2003-2023 Dominik Reichl <dominik.reichl@t-online.de>
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

<#
    .SYNOPSIS
    Compiles KeePassLib and deploys PowerPass for the current user or system-wide.
    .PARAMETER Target
    The deployment Target either CurrentUser or the System. Defaults to CurrentUser. Deploying
    to the System requires administrative privileges in the current PowerShell host. Deploying
    for the current user will install PowerPass into the default Modules folder for the user
    account running the PowerShell host.
    .PARAMETER Path
    An optional Modules path where you want to deploy PowerPass. This path must exist. By
    default, this script will deploy PowerPass into the current user's or default system's
    Modules directory. If neither of these paths exist, or you simply want to deploy PowerPass
    elsewhere, specify the target Modules folder using the Path parameter.
#>
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("CurrentUser","System")]
    [string]
    $Target = "CurrentUser",
    [Parameter(Mandatory=$false)]
    [string]
    $Path
)

# Assert PowerShell version
Write-Host "Checking this version of PowerShell"
if( $PSVersionTable.PSVersion.Major -ne 5 ) {
    throw "The PowerPass module is only compatible with PowerShell 5.1."
}

# Set the working directory to $PSScriptRoot
Set-Location $PSScriptRoot

# Locate the deployment folder
Write-Host "Locating the deployment folder"
$modulesRoot = ""
if( [String]::IsNullOrEmpty( $Path ) ) {
    switch( $Target ) {
        "CurrentUser" {
            $modulesRoot = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
            if( -not (Test-Path $modulesRoot) ) {
                $answer = Read-Host "Your Windows PowerShell modules folder does not exist. Would you like to create it? [Y/n]"
                if( -not $answer ) {
                    New-Item -Path $modulesRoot -ItemType Directory | Out-Null
                }
                if( ($answer -eq "y") -or ($answer -eq "Y") ) {
                    New-Item -Path $modulesRoot -ItemType Directory | Out-Null
                }
                if( ($answer -eq "n") -or ($answer -eq "N") ) {
                    $modulesRoot = Read-Host "Please type in an alternate path for deployment"
                }
            }
        }
        "System" {
            $modulesRoot = Join-Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules"
        }
        default {
            throw "Illegal value for Target parameter"
        }
    }
    if( -not (Test-Path $modulesRoot) ) {
        throw "Could not find a suitable Modules path, please specify using Path parameter"
    }
} else {
    $modulesRoot = $Path
    if( -not (Test-Path $modulesRoot) ) {
        throw "Could not open directory specified by Path parameter"
    }
}
Write-Host "Deploying to $modulesRoot"

# Check for modules root in the path
Write-Host "Checking PSModulePath for deployment folder"
if( -not ($env:PSModulePath -like "*$modulesRoot*") ) {
    Write-Warning "The deployment folder is not in the PSModulePath. If you are using OneDrive Backup for your documents, you will need to add this directory to your PSModulePath or move PoewrPass after deployment."
    Write-Host "For more information, please see https://chopinrlz.github.io/powerpass/onedrivebackup"
    $answer = Read-Host "Do you want to proceed? [N/y]"
    if( $answer -ne 'y' ) {
        throw "Installation cancelled by user"
    }
}

# Check for an existing salt
Write-Host "Checking for an existing salt"
$saltFile = Join-Path -Path $PSScriptRoot -ChildPath "powerpass.salt"
if( Test-Path $saltFile ) {
    Write-Warning "Salt already exists for a deployment. If you proceed, your old salt will be erased and you may lose ALL your existing locker secrets."
    $answer = Read-Host "Do you want to proceed? [N/y]"
    if( ($answer -eq 'y') -or ($answer -eq 'Y') ) {
        Remove-Item $saltFile -Force
        if( Test-Path $saltFile ) {
            throw "Could not remove old salt file"
        }
    } else {
        throw "Installation cancelled by user"
    }
}

# Remove the existing KeePassLib assembly if it exists
Write-Host "Cleaning up old builds"
$oldBuild = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
if( Test-Path $oldBuild ) {
    Remove-Item $oldBuild -Force
    if( Test-Path $oldBuild ) {
        throw "Could not remove previous build of KeePassLib.dll"
    }
}

# Get the location of the C# compiler for this runtime
Write-Host "Locating the C# compiler"
$cscDir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
$cscPath = Join-Path -Path $cscDir -ChildPath "csc.exe"
if( -not (Test-Path $cscPath) ) {
    throw "No C# compiler could be found in the current runtime directory"
}

# Build the compiler arguments for KeePassLib
Write-Host "Building the compiler arguments for KeePassLib"
$compilerArgs = @()
$compilerArgs += '/target:library'
$compilerArgs += '/out:KeePassLib.dll'
Get-ChildItem -Path '.\KeePassLib' -Recurse -Filter "*.cs" | ForEach-Object {
    $compilerArgs += ($_.FullName)
}

# Compile KeePassLib
Write-Host "Compiling KeePassLib"
& $cscPath $compilerArgs | Out-Null

# Verify the compiled assembly
Write-Host "Verifying the compiled assembly"
$assemblyPath = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
if( -not (Test-Path $assemblyPath) ) {
    throw "KeePassLib was not compiled successfully"
}
[System.Reflection.Assembly]::LoadFrom( $assemblyPath ) | Out-Null
$database = New-Object -TypeName "KeePassLib.PwDatabase"
if( -not $database ) {
    throw "There was an error loading KeePassLib, the PwDatabase object could not be instantiated"
}

# Generate a salt for the installation
Write-Host "Generating a salt for this deployment"
[System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
$saltShaker = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = [System.Byte[]]::CreateInstance( [System.Byte], 32 )
$saltShaker.GetBytes( $salt )
$encSalt = [System.Security.Cryptography.ProtectedData]::Protect($salt,$null,"LocalMachine")
$saltText = [System.Convert]::ToBase64String($encSalt)
Out-File -InputObject $saltText -FilePath $saltFile -Force
if( -not (Test-Path $saltFile) ) {
    throw "Unable to generate a salt for the installation"
}

# Deploy the module
Write-Host "Deploying the PowerPass module"
$targetLocation = Join-Path -Path $modulesRoot -ChildPath "PowerPass"
if( -not (Test-Path $targetLocation) ) {
    New-Item -Path $modulesRoot -Name "PowerPass" -ItemType Directory | Out-Null
}
if( -not (Test-Path $targetLocation) ) {
    throw "Failed to create deployment folder, $modulesRoot is not writable"
}
$itemsToDeploy = @("LICENSE","TestDatabase.kdbx","KeePassLib.dll","powerpass.salt","PowerPass\PowerPass.ps1","PowerPass\PowerPass.psd1","PowerPass\PowerPass.psm1",".\PowerPass\StatusLogger.cs",".\PowerPass\Extensions.cs")
$itemsToDeploy | Copy-Item -Destination $targetLocation -Force