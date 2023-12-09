#
# Release build script for PowerPass
#
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#
param(
    [switch]
    $Clean
)

# Set flag for Windows or Linux paths
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    $IsWindows = $true
}

# Move to the root of the repo and save the caller's path
$callerLocation = Get-Location
if( $IsWindows ) {
    Set-Location -Path "$PSScriptRoot\.."
} else {
    Set-Location -Path "$PSScriptRoot/.."
}

# Define the main directory with the resources
$dirPowerPass = Join-Path -Path (Get-Location) -ChildPath "module"

# Declare each module file for the release and verify presence
$aesCryptoCs = Join-Path -Path $dirPowerPass -ChildPath "AesCrypto.cs"
$extensionsCs = Join-Path -Path $dirPowerPass -ChildPath "Extensions.cs"
$powerPassAesPsd1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Aes.psd1"
$powerPassAesPsm1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Aes.psm1"
$powerPassDpApiPsd1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.DpApi.psd1"
$powerPassDpApiPsm1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.DpApi.psm1"
$powerPassPs1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.ps1"
$statusLoggerCs = Join-Path -Path $dirPowerPass -ChildPath "StatusLogger.cs"
$powerPassFiles = @($aesCryptoCs,$extensionsCs,$powerPassAesPsd1,$powerPassAesPsm1,$powerPassDpApiPsd1,$powerPassDpApiPsm1,$powerPassPs1,$statusLoggerCs)
foreach( $file in $powerPassFiles ) {
    if( -not (Test-Path $file) ) {
        throw "$file is missing"
    }
}

# Declare each root file for the release and verify presence
$deployPowerPassPs1 = Join-Path -Path (Get-Location) -ChildPath "Deploy-PowerPass.ps1"
$keePassLibDll = Join-Path -Path (Get-Location) -ChildPath "KeePassLib.dll"
$license = Join-Path -Path (Get-Location) -ChildPath "LICENSE"
$readmeMd = Join-Path -Path (Get-Location) -ChildPath "README.md"
$testDatabaseKdbx = Join-Path -Path (Get-Location) -ChildPath "TestDatabase.kdbx"
$rootFiles = @($deployPowerPassPs1,$keePassLibDll,$license,$readmeMd,$testDatabaseKdbx)
foreach( $file in $rootFiles ) {
    if( -not (Test-Path $file) ) {
        throw "$file is missing"
    }
}

# Check the release version numbers, make sure they are consistent
$powerPassAesManifest = Import-PowerShellDataFile $powerPassAesPsd1
$powerPassDpApiManifest = Import-PowerShellDataFile $powerPassDpApiPsd1
if( $powerPassDpApiManifest.ModuleVersion -ne $powerPassAesManifest.ModuleVersion ) {
    throw "Module versions are not equivalent"
}

# Initialize the release files
$zipFileName = "PowerPass-$($powerPassAesManifest.ModuleVersion).zip"
$tarGzFileName = "PowerPass-$($powerPassAesManifest.ModuleVersion).tar.gz"
$releaseZip = Join-Path -Path (Get-Location) -ChildPath $zipFileName
$releaseTarGz = Join-Path -Path (Get-Location) -ChildPath $tarGzFileName
if( Test-Path $releaseZip ) { Remove-Item -Path $releaseZip -Force }
if( Test-Path $releaseTarGz ) { Remove-Item -Path $releaseTarGz -Force }

# Declare the release directory
$releaseDir = Join-Path -Path (Get-Location) -ChildPath "release"
$releaseDirSubDir = Join-Path -Path $releaseDir -ChildPath "module"
if( Test-path $releaseDir ) { Remove-Item -Path $releaseDir -Recurse -Force }
if( $Clean ) { exit }

# Build the release directory
$null = New-Item -Path $releaseDir -ItemType Directory
$null = New-Item -Path $releaseDirSubDir -ItemType Directory

# Copy the PowerPass files into the release directory
$rootFiles | Copy-Item -Destination $releaseDir -Force
$powerPassFiles | Copy-Item -Destination $releaseDirSubDir -Force

# Create the release archive ZIP file
if( $IsWindows ) {
    Compress-Archive -Path "$releaseDir\*" -DestinationPath $releaseZip -CompressionLevel Optimal
} else {
    Compress-Archive -Path "$releaseDir/*" -DestinationPath $releaseZip -CompressionLevel Optimal
}

# Create the release archive TAR.GZ file
Set-Location -Path $releaseDir
if( $IsWindows ) {
    & tar @('-czf',"..\$tarGzFileName",'.')
} else {
    & tar @('-czf',"../$tarGzFileName",'.')
}
Set-Location -Path ".."

# Clean up temporary files
if( Test-path $releaseDir ) { Remove-Item -Path $releaseDir -Recurse -Force }

# Compute the hash of each release file
$hashFile = Join-Path -Path (Get-Location) -ChildPath "hash.txt"
if( Test-Path $hashFile ) { Remove-Item -Path $hashFile -Force }
Get-FileHash -Path $releaseZip | Out-File -FilePath $hashFile -Append
Get-FileHash -Path $releaseTarGz | Out-File -FilePath $hashFile -Append

# Move the user back to the path the called from
Set-Location -Path $callerLocation