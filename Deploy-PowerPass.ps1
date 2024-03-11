<#
    Deployment script for PowerPass AES and PowerPass DP API
    Copyright 2023-2024 by The Daltas Group LLC.
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
    $modulesRoot = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\WindowsPowerShell\Modules"
    $answer = Read-Host "Please indicate the edition of PowerPass you want to deploy: (1) AES or (2) DP API with KeePass support? [1/2]"
    $oneDriveCheck = $true
    switch( $answer ) {
        "1" {
            $installation = $powerPassAes
        }
        "2" {
            $installation = $powerPassDpApi
        }
        default {
            $installation = $powerPassAes
        }
    }
} elseif( $PSVersionTable.PSVersion.Major -eq 7 ) {
    if( $IsWindows ) {
        $modulesRoot = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell\Modules"
        $oneDriveCheck = $true
    } elseif( $IsLinux ) {
        $modulesRoot = Join-Path -Path "~" -ChildPath ".local/share/powershell/Modules"
    } elseif( $IsMacOS ) {
        $modulesRoot = Join-Path -Path "~" -ChildPath ".local/share/powershell/Modules"
    } else {
        throw "Operating system not supported"
    }
    $installation = $powerPassAes
} else {
    throw "Unsupported PowerShell version"
}

# Prompt for use of TPM
if( $IsLinux ) {
    # Removed, committed by mistake
}

# Check for OneDrive backup
if( $oneDriveCheck ) {
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
                        Write-Warning "$path does not exist"
                    }
                } else {
                    throw "Deployment cancelled by user"
                }
            }
        }
    }
}

# Test the deployment folder
if( -not (Test-Path $modulesRoot) ) {
    New-Item -Path $modulesRoot -ItemType Directory
    if( -not (Test-Path $modulesRoot) ) {
        throw "Unable to create deployment folder"
    }
}

# Create the deployment location
$targetLocation = Join-Path -Path $modulesRoot -ChildPath "PowerPass"
Write-Output "Install path: $targetLocation"

# Perform the DP API and KeePass specific tasks
$deploySalt = $false
if( $installation -eq $powerPassDpApi ) {
    # Check for KeePassLib
    $keePassLib = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
    if( Test-Path $keePassLib ) {
        $answer = Read-Host "We have detected KeePassLib bundled with this deployment. Would you like to use it? [Y/n]"
        if( ($answer -eq 'n') -or ($answer -eq 'N') ) {
            Remove-Item $keePassLib -Force
            if( Test-Path $keePassLib ) {
                throw "Could not remove previous build of KeePassLib.dll"
            }
        }
    }

    # Build KeePassLib
    if( -not (Test-Path $keePassLib) ) {
        # Get the location of the C# compiler for this runtime
        $cscDir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
        $cscPath = Join-Path -Path $cscDir -ChildPath "csc.exe"
        if( -not (Test-Path $cscPath) ) {
            throw "No C# compiler could be found in the current runtime directory"
        }

        # Build the compiler arguments for KeePassLib
        $compilerArgs = @()
        $compilerArgs += '/target:library'
        $compilerArgs += '/out:KeePassLib.dll'
        Get-ChildItem -Path '.\KeePassLib' -Recurse -Filter "*.cs" | ForEach-Object {
            $compilerArgs += ($_.FullName)
        }

        # Compile KeePassLib
        & $cscPath $compilerArgs | Out-Null
    }

    # Verify the compiled assembly
    if( -not (Test-Path $keePassLib) ) {
        throw "KeePassLib was not compiled successfully"
    }
    [System.Reflection.Assembly]::LoadFrom( $keePassLib ) | Out-Null
    $database = New-Object -TypeName "KeePassLib.PwDatabase"
    if( -not $database ) {
        throw "There was an error loading KeePassLib, the PwDatabase object could not be instantiated"
    }

    # Generate a salt for the installation
    $saltFile = Join-Path -Path $targetLocation -ChildPath "powerpass.salt"
    if( -not (Test-Path $saltFile) ) {
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
            $deploySalt = $true
        }
    }
}

# Create the deployment directory
if( -not (Test-Path $targetLocation) ) {
    New-Item -Path $modulesRoot -Name "PowerPass" -ItemType Directory | Out-Null
}
if( -not (Test-Path $targetLocation) ) {
    throw "Failed to create deployment folder, $modulesRoot is not writable"
}

# Deploy the module
$missingFiles = $false
switch( $installation ) {
    $powerPassAes {
        $itemsToDeploy = @("LICENSE","module\PowerPass.ps1",".\module\AesCrypto.cs",".\module\PowerPass.Common.ps1",".\module\Compression.cs")
        $itemsToDeploy | Copy-Item -Destination $targetLocation -Force
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.Aes.psd1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psd1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.Aes.psm1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psm1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        $verified = @("LICENSE","PowerPass.ps1","PowerPass.psd1","PowerPass.psm1","AesCrypto.cs","PowerPass.Common.ps1","Compression.cs")
        $verified | ForEach-Object {
            $verifiedPath = Join-Path -Path $targetLocation -ChildPath $_
            if( -not (Test-Path $verifiedPath) ) {
                Write-Warning "Missing file: $verifiedPath"
                $missingFiles = $true
            }
        }
    }
    $powerPassDpApi {
        $itemsToDeploy = @("LICENSE","TestDatabase.kdbx","KeePassLib.dll","module\PowerPass.ps1",".\module\StatusLogger.cs",".\module\Extensions.cs",".\module\AesCrypto.cs",".\module\PowerPass.Common.ps1",".\module\Compression.cs")
        if( $deploySalt ) {
            $itemsToDeploy += "powerpass.salt"
        }
        $itemsToDeploy | Copy-Item -Destination $targetLocation -Force
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.DpApi.psd1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psd1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        $sourceFile = Join-Path -Path $PSScriptRoot -ChildPath "module\PowerPass.DpApi.psm1"
        $targetFile = Join-Path -Path $targetLocation -ChildPath "PowerPass.psm1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        $verified = @("LICENSE","TestDatabase.kdbx","KeePassLib.dll","PowerPass.ps1","PowerPass.psd1","PowerPass.psm1","StatusLogger.cs","Extensions.cs","powerpass.salt","PowerPass.Common.ps1","Compression.cs")
        $verified | ForEach-Object {
            $verifiedPath = Join-Path -Path $targetLocation -ChildPath $_
            if( -not (Test-Path $verifiedPath) ) {
                Write-Warning "Missing file: $verifiedPath"
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