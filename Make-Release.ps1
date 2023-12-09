# Define the main directory with the resources
$dirPowerPass = Join-Path -Path $PSScriptRoot -ChildPath "module"

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
$deployPowerPassPs1 = Join-Path -Path $PSScriptRoot -ChildPath "Deploy-PowerPass.ps1"
$keePassLibDll = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
$license = Join-Path -Path $PSScriptRoot -ChildPath "LICENSE"
$readmeMd = Join-Path -Path $PSScriptRoot -ChildPath "README.md"
$testDatabaseKdbx = Join-Path -Path $PSScriptRoot -ChildPath "TestDatabase.kdbx"
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
$releaseZip = Join-Path -Path $PSScriptRoot -ChildPath $zipFileName
$releaseTarGz = Join-Path -Path $PSScriptRoot -ChildPath $tarGzFileName
if( Test-Path $releaseZip ) { Remove-Item -Path $releaseZip -Force }
if( Test-Path $releaseTarGz ) { Remove-Item -Path $releaseTarGz -Force }

# Set $IsWindows if we're in Windows PowerShell
if( $PSVersionTable.PSVersion.Major -eq 5 ) {
    $IsWindows = $true
}

# Build the release directory
$releaseDir = Join-Path -Path $PSScriptRoot -ChildPath "release"
$releaseDirSubDir = Join-Path -Path $releaseDir -ChildPath "module"
if( Test-path $releaseDir ) { Remove-Item -Path $releaseDir -Recurse -Force }
$null = New-Item -Path $releaseDir -ItemType Directory
$null = New-Item -Path $releaseDirSubDir -ItemType Directory
$rootFiles | Copy-Item -Destination $releaseDir -Force
$powerPassFiles | Copy-Item -Destination $releaseDirSubDir -Force

# Create the release archive ZIP file
if( $IsWindows ) {
    Compress-Archive -Path "$releaseDir\*" -DestinationPath $releaseZip -CompressionLevel Optimal
} else {
    Compress-Archive -Path "$releaseDir/*" -DestinationPath $releaseZip -CompressionLevel Optimal
}

# Create the release archive TAR.GZ file
Set-Location $releaseDir
if( $IsWindows ) {
    & tar @('-czf',"..\$tarGzFileName",'.')
} else {
    & tar @('-czf',"../$tarGzFileName",'.')
}
Set-Location $PSScriptRoot

# Clean up temporary files
if( Test-path $releaseDir ) { Remove-Item -Path $releaseDir -Recurse -Force }

# Compute the hash of each release file
$hashFile = Join-Path -Path $PSScriptRoot -ChildPath "hash.txt"
if( Test-Path $hashFile ) { Remove-Item -Path $hashFile -Force }
Get-FileHash -Path $releaseZip | Out-File -FilePath $hashFile -Append
Get-FileHash -Path $releaseTarGz | Out-File -FilePath $hashFile -Append