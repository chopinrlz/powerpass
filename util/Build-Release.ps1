#
# Release build script for PowerPass
#
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#

<#
    .SYNOPSIS
    Builds a release of PowerPass or cleans up all release files.
    .PARAMETER Clean
    If specified, will clean up the tree by removing release files.
#>
param(
    [switch]
    $Clean
)

# Verify version of PowerShell
Write-Progress -Activity "Building KeePass Release" -Status "Checking PowerShell version" -PercentComplete 10
if( $PSVersionTable.PSVersion.Major -ne 5 ) {
    throw "This script can only be run in Windows PowerShell"
}

# Move to the root of the repo and save the caller's path
Write-Progress -Activity "Building KeePass Release" -Status "Moving to root fooder" -PercentComplete 15
$callerLocation = Get-Location
Set-Location -Path "$PSScriptRoot\.."

# Compile the KeePassLib assembly
Write-Progress -Activity "Building KeePass Release" -Status "Compiling the KeePass assembly" -PercentComplete 20
$keePassLib = Join-Path -Path (Get-Location) -ChildPath "KeePassLib.dll"
if( Test-Path $keePassLib ) { Remove-Item -Path $keePassLib -Force }
if( -not $Clean ) {
    $cscDir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
    $cscPath = Join-Path -Path $cscDir -ChildPath "csc.exe"
    if( -not (Test-Path $cscPath) ) {
        throw "No C# compiler could be found in the current runtime directory"
    }
    $compilerArgs = @()
    $compilerArgs += '/target:library'
    $compilerArgs += '/out:KeePassLib.dll'
    Get-ChildItem -Path '.\KeePassLib' -Recurse -Filter "*.cs" | ForEach-Object {
        $compilerArgs += ($_.FullName)
    }
    & $cscPath $compilerArgs | Out-Null
}

# Define the main directory with the resources
Write-Progress -Activity "Building KeePass Release" -Status "Declaring build resources" -PercentComplete 30
$dirPowerPass = Join-Path -Path (Get-Location) -ChildPath "module"

# Declare each module file for the release and verify presence
$aesCryptoCs = Join-Path -Path $dirPowerPass -ChildPath "AesCrypto.cs"
$compressionCs = Join-Path -Path $dirPowerPass -ChildPath "Compression.cs"
$conversionCs = Join-Path -Path $dirPowerPass -ChildPath "Conversion.cs"
$extensionsCs = Join-Path -Path $dirPowerPass -ChildPath "Extensions.cs"
$powerPassCommon = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Common.ps1"
$powerPassAesPsd1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Aes.psd1"
$powerPassAesPsm1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Aes.psm1"
$powerPassDpApiPsd1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.DpApi.psd1"
$powerPassDpApiPsm1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.DpApi.psm1"
$powerPassPs1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.ps1"
$statusLoggerCs = Join-Path -Path $dirPowerPass -ChildPath "StatusLogger.cs"
$powerPassFiles = @($aesCryptoCs,$compressionCs,$extensionsCs,$powerPassAesPsd1,$powerPassAesPsm1,$powerPassDpApiPsd1,$powerPassDpApiPsm1,$powerPassPs1,$statusLoggerCs,$powerPassCommon,$conversionCs)
foreach( $file in $powerPassFiles ) {
    if( -not (Test-Path $file) ) {
        throw "$file is missing"
    }
}

# Declare each root file for the release and verify presence
$rootFiles = @()
$rootFiles += (Join-Path -Path (Get-Location) -ChildPath "Deploy-PowerPass.ps1")
if( -not $Clean ) {
    $rootFiles += (Join-Path -Path (Get-Location) -ChildPath "KeePassLib.dll")
}
$rootFiles += (Join-Path -Path (Get-Location) -ChildPath "LICENSE")
$rootFiles += (Join-Path -Path (Get-Location) -ChildPath "README.md")
$rootFiles += (Join-Path -Path (Get-Location) -ChildPath "TestDatabase.kdbx")
foreach( $file in $rootFiles ) {
    if( -not (Test-Path $file) ) {
        throw "$file is missing"
    }
}

# Check the release version numbers, make sure they are consistent
Write-Progress -Activity "Building KeePass Release" -Status "Interrogating the manifests" -PercentComplete 40
$powerPassAesManifest = Import-PowerShellDataFile $powerPassAesPsd1
$powerPassDpApiManifest = Import-PowerShellDataFile $powerPassDpApiPsd1
if( $powerPassDpApiManifest.ModuleVersion -ne $powerPassAesManifest.ModuleVersion ) {
    throw "Module versions are not equivalent"
}

# Initialize the release files
Write-Progress -Activity "Building KeePass Release" -Status "Declaring the output files" -PercentComplete 50
$zipFileName = "PowerPass-$($powerPassAesManifest.ModuleVersion).zip"
$tarGzFileName = "PowerPass-$($powerPassAesManifest.ModuleVersion).tar.gz"
$releaseZip = Join-Path -Path (Get-Location) -ChildPath $zipFileName
$releaseTarGz = Join-Path -Path (Get-Location) -ChildPath $tarGzFileName
if( Test-Path $releaseZip ) { Remove-Item -Path $releaseZip -Force }
if( Test-Path $releaseTarGz ) { Remove-Item -Path $releaseTarGz -Force }

# Declare the release directory
Write-Progress -Activity "Building KeePass Release" -Status "Initializing the build folder" -PercentComplete 60
$releaseDir = Join-Path -Path (Get-Location) -ChildPath "release"
$releaseDirSubDir = Join-Path -Path $releaseDir -ChildPath "module"
if( Test-path $releaseDir ) { Remove-Item -Path $releaseDir -Recurse -Force }
if( $Clean ) {
    $hashFile = Join-Path -Path (Get-Location) -ChildPath "hash.json"
    if( Test-Path $hashFile ) { Remove-Item -Path $hashFile -Force }
    Set-Location -Path $callerLocation
    exit
}

# Build the release directory
Write-Progress -Activity "Building KeePass Release" -Status "Copying release assets" -PercentComplete 70
$null = New-Item -Path $releaseDir -ItemType Directory
$null = New-Item -Path $releaseDirSubDir -ItemType Directory

# Copy the PowerPass files into the release directory
$rootFiles | Copy-Item -Destination $releaseDir -Force
$powerPassFiles | Copy-Item -Destination $releaseDirSubDir -Force

# Create the release archive ZIP file
Write-Progress -Activity "Building KeePass Release" -Status "Creating release archives" -PercentComplete 80
Compress-Archive -Path "$releaseDir\*" -DestinationPath $releaseZip -CompressionLevel Optimal

# Create the release archive TAR.GZ file
Set-Location -Path $releaseDir
& tar @('-czf',"..\$tarGzFileName",'.')
Set-Location -Path ".."

# Clean up temporary files
if( Test-path $releaseDir ) { Remove-Item -Path $releaseDir -Recurse -Force }

# Compute the hash of each release file
Write-Progress -Activity "Building KeePass Release" -Status "Generating release hashes" -PercentComplete 90
$hashFile = Join-Path -Path (Get-Location) -ChildPath "hash.md"
if( Test-Path $hashFile ) { Remove-Item -Path $hashFile -Force }
@"
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| $tarGzFileName  | ``$((Get-FileHash -Path $releaseTarGz).Hash)`` |
| $zipFileName     | ``$((Get-FileHash -Path $releaseZip).Hash)`` |
"@ | Out-File -FilePath $hashFile -Append

# Move the user back to the path the called from
Write-Progress -Activity "Building KeePass Release" -Status "Complete" -PercentComplete 100
Set-Location -Path $callerLocation