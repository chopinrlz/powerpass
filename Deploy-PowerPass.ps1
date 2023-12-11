<#
    Deployment script for PowerPass AES and PowerPass DP API
    Copyright 2023 by The Daltas Group LLC.
    The KeePassLib source code is copyright (C) 2003-2023 Dominik Reichl <dominik.reichl@t-online.de>
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#>

# Set the working directory to $PSScriptRoot
Set-Location $PSScriptRoot

# Constants for editions
$powerPassAes = "PowerPass.Aes.psm1"
$powerPassDpApi = "PowerPass.DpApi.psm1"
$installation = "tbd"
$modulesRoot = "tbd"
$oneDriveCheck = $false

# Detect the PowerShell version and operating system, set the deployment version
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    Write-Output "Windows PowerShell 5 detected"
    $modulesRoot = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
    $answer = Read-Host "Please indicate the edition of PowerPass you want to deploy: (1) AES or (2) DP API with KeePass support? [1/2]"
    $oneDriveCheck = $true
    switch( $answer ) {
        "1" {
            Write-Output "Deploying PowerPass AES"
            $installation = $powerPassAes
        }
        "2" {
            Write-Output "Deploying PowerPass DP API with KeePass support"
            $installation = $powerPassDpApi
        }
        default {
            Write-Output "Deploying PowerPass AES"
            $installation = $powerPassAes
        }
    }
} elseif( $PSVersionTable.PSVersion.Major -eq 7 ) {
    Write-Output "PowerShell 7 detected"
    if( $IsWindows ) {
        Write-Output "Windows operating system detected"
        $modulesRoot = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules"
        $oneDriveCheck = $true
    } elseif( $IsLinux ) {
        Write-Output "Linux operating system detected"
        $modulesRoot = Join-Path -Path "~" -ChildPath ".local/share/powershell/Modules"
    } elseif( $IsMacOS ) {
        Write-Output "MacOS operating system detected"
        $modulesRoot = Join-Path -Path "~" -ChildPath ".local/share/powershell/Modules"
    } else {
        throw "Operating system not supported"
    }
    $installation = $powerPassAes
} else {
    Write-Output "PowerShell $($PSVersionTable.PSVersion.Major) detected"
    throw "Unsupported PowerShell version"
}

# Check for OneDrive backup
if( $oneDriveCheck ) {
    Write-Output "Checking PSModulePath for deployment folder"
    $path = $env:PSModulePath -split ";"
    if( -not ($path -contains $modulesRoot) ) {
        $search = "tbd"
        switch( $PSVersionTable.PSVersion.Major ) {
            5 {
                $search = "*Documents\WindowsPowerShell\Modules"
            }
            7 {
                $search = "*Documents\PowerShell\Modules"
            }
            default {
                throw "Unsupported PowerShell version"
            }
        }
        $newPath = $path -like $search
        if( $newPath ) {
            Write-Output "Found alternate path"
            $modulesRoot = $newPath
        } else {
            Write-Warning "$modulesRoot is not in the PSModulePath and no suitable alternative could be found"
            while( $true ) {
                $path = Read-Host "Please provide an alternate path or press enter to cancel deployment:"
                if( $path ) {
                    if( Test-Path $path ) {
                        $modulesRoot = $path
                        break
                    } else {
                        Write-Output "$path does not exist"
                    }
                } else {
                    throw "Deployment cancelled by user"
                }
            }
        }
    }
} else {
    Write-Output "Skipping OneDrive check for Windows"
}

# Test the deployment folder
if( -not (Test-Path $modulesRoot) ) {
    Write-Output "Creating modules directory"
    New-Item -Path $modulesRoot -ItemType Directory
    if( -not (Test-Path $modulesRoot) ) {
        throw "Unable to create deployment folder"
    }
} else {
    Write-Output "Module folder exists"
}

# Create the deployment location
$targetLocation = Join-Path -Path $modulesRoot -ChildPath "PowerPass"
Write-Output "Target folder is $targetLocation"

# Perform the DP API and KeePass specific tasks
$deploySalt = $false
if( $installation -eq $powerPassDpApi ) {
    # Check for KeePassLib
    Write-Output "Checking for KeePassLib"
    $keePassLib = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
    if( Test-Path $keePassLib ) {
        $answer = Read-Host "We have detected KeePassLib bundled with this deployment. Would you like to use it? [Y/n]"
        if( ($answer -eq 'n') -or ($answer -eq 'N') ) {
            Write-Output "Removing current build and compiling KeePassLib from source"
            Remove-Item $keePassLib -Force
            if( Test-Path $keePassLib ) {
                throw "Could not remove previous build of KeePassLib.dll"
            }
        } else {
            Write-Output "Deploying PowerPass with bundled KeePassLib"
        }
    } else {
        Write-Output "No bundled KeePassLib"
    }

    # Build KeePassLib
    if( -not (Test-Path $keePassLib) ) {
        # Get the location of the C# compiler for this runtime
        Write-Output "Locating the C# compiler"
        $cscDir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
        $cscPath = Join-Path -Path $cscDir -ChildPath "csc.exe"
        if( -not (Test-Path $cscPath) ) {
            throw "No C# compiler could be found in the current runtime directory"
        }

        # Build the compiler arguments for KeePassLib
        Write-Output "Building the compiler arguments for KeePassLib"
        $compilerArgs = @()
        $compilerArgs += '/target:library'
        $compilerArgs += '/out:KeePassLib.dll'
        Get-ChildItem -Path '.\KeePassLib' -Recurse -Filter "*.cs" | ForEach-Object {
            $compilerArgs += ($_.FullName)
        }

        # Compile KeePassLib
        Write-Output "Compiling KeePassLib"
        & $cscPath $compilerArgs | Out-Null
    } else {
        Write-Output "Detected KeePassLib with release"
    }

    # Verify the compiled assembly
    Write-Output "Verifying the compiled assembly"
    if( -not (Test-Path $keePassLib) ) {
        throw "KeePassLib was not compiled successfully"
    }
    [System.Reflection.Assembly]::LoadFrom( $keePassLib ) | Out-Null
    $database = New-Object -TypeName "KeePassLib.PwDatabase"
    if( -not $database ) {
        throw "There was an error loading KeePassLib, the PwDatabase object could not be instantiated"
    }

    # Generate a salt for the installation
    Write-Output "Checking for an existing salt"
    $saltFile = Join-Path -Path $targetLocation -ChildPath "powerpass.salt"
    if( Test-Path $saltFile ) {
        Write-Output "Detected existing module salt"
    } else {
        Write-Output "Generating a salt for this deployment"
        $saltFile = Join-Path -Path $PSScriptRoot -ChildPath "powerpass.salt"
        [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
        $saltShaker = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $salt = [System.Byte[]]::CreateInstance( [System.Byte], 32 )
        $saltShaker.GetBytes( $salt )
        $encSalt = [System.Security.Cryptography.ProtectedData]::Protect($salt,$null,"LocalMachine")
        $saltText = [System.Convert]::ToBase64String($encSalt)
        Out-File -InputObject $saltText -FilePath $saltFile -Force
        if( -not (Test-Path $saltFile) ) {
            throw "Unable to generate a salt for the installation"
        } else {
            Write-Output "Salt generated successfully"
            $deploySalt = $true
        }
    }
} else {
    Write-Output "Skipping DP API steps"
}

# Create the deployment directory
Write-Output "Deploying the PowerPass module"
if( -not (Test-Path $targetLocation) ) {
    Write-Output "Creating the PowerPass directory"
    New-Item -Path $modulesRoot -Name "PowerPass" -ItemType Directory | Out-Null
} else {
    Write-Output "Target location already exists"
}
if( -not (Test-Path $targetLocation) ) {
    throw "Failed to create deployment folder, $modulesRoot is not writable"
}

# Deploy the module
Write-Output "Installing module files"
$missingFiles = $false
switch( $installation ) {
    $powerPassAes {
        Write-Output "Copying AES common files"
        $itemsToDeploy = @("LICENSE","module\PowerPass.ps1",".\module\AesCrypto.cs")
        $itemsToDeploy | Copy-Item -Destination $targetLocation -Force

        Write-Output "Copying AES manifest"
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.Aes.psd1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psd1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        Write-Output "Copying AES module"
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.Aes.psm1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psm1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        Write-Output "Verifying the installation"
        $verified = @("LICENSE","PowerPass.ps1","PowerPass.psd1","PowerPass.psm1","AesCrypto.cs")
        $verified | ForEach-Object {
            $verifiedPath = Join-Path -Path $targetLocation -ChildPath $_
            if( -not (Test-Path $verifiedPath) ) {
                Write-Warning "$verifiedPath missing"
                $missingFiles = $true
            }
        }
    }
    $powerPassDpApi {
        Write-Output "Copying DP API common files"
        $itemsToDeploy = @("LICENSE","TestDatabase.kdbx","KeePassLib.dll","module\PowerPass.ps1",".\module\StatusLogger.cs",".\module\Extensions.cs",".\module\AesCrypto.cs")
        if( $deploySalt ) {
            $itemsToDeploy += "powerpass.salt"
        }
        $itemsToDeploy | Copy-Item -Destination $targetLocation -Force

        Write-Output "Copying DP API manifest"
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.DpApi.psd1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psd1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        Write-Output "Copying DP API module"
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.DpApi.psm1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psm1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        Write-Output "Verifying the installation"
        $verified = @("LICENSE","TestDatabase.kdbx","KeePassLib.dll","PowerPass.ps1","PowerPass.psd1","PowerPass.psm1","StatusLogger.cs","Extensions.cs","powerpass.salt")
        $verified | ForEach-Object {
            $verifiedPath = Join-Path -Path $targetLocation -ChildPath $_
            if( -not (Test-Path $verifiedPath) ) {
                Write-Warning "$verifiedPath missing"
                $missingFiles = $true
            }
        }
    }
}

# Report on status
if( $missingFiles ) {
    Write-Output "PowerPass deployed with warnings, please review messages above"
} else {
    Write-Output "PowerPass deployed successfully"
}