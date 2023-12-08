# Define the main directory with the resources
$dirPowerPass = Join-Path -Path $PSScriptRoot -ChildPath "PowerPass"

# Define each file of the release
$aesCryptoCs = Join-Path -Path $dirPowerPass -ChildPath "AesCrypto.cs"
$extensionsCs = Join-Path -Path $dirPowerPass -ChildPath "Extensions.cs"
$powerPassAesPsd1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Aes.psd1"
$powerPassAesPsm1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.Aes.psm1"
$powerPassDpApiPsd1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.DpApi.psd1"
$powerPassDpApiPsm1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.DpApi.psm1"
$powerPassPs1 = Join-Path -Path $dirPowerPass -ChildPath "PowerPass.ps1"
$statusLoggerCs = Join-Path -Path $dirPowerPass -ChildPath "StatusLogger.cs"

# Define each file in the current directory
$deployPowerPassPs1 = Join-Path -Path $PSScriptRoot -ChildPath "Deploy-PowerPass.ps1"
$keePassLibDll = Join-Path -Path $PSScriptRoot -ChildPath "KeePassLib.dll"
$license = Join-Path -Path $PSScriptRoot -ChildPath "LICENSE"
$readmeMd = Join-Path -Path $PSScriptRoot -ChildPath "README.md"
$testDatabaseKdbx = Join-Path -Path $PSScriptRoot -ChildPath "TestDatabase.kdbx"

# Check the release version numbers, make sure they are consistent
$powerPassAesManifest = Import-PowerShellDataFile $powerPassAesPsd1
$powerPassDpApiManifest = Import-PowerShellDataFile $powerPassDpApiPsd1

# Create the release archives
$release = @($aesCryptoCs,$extensionsCs,$powerPassAesPsd1,$powerPassAesPsm1,$powerPassDpApiPsd1,$powerPassDpApiPsm1,$powerPassPs1,$statusLoggerCs,$deployPowerPassPs1,$keePassLibDll,$license,$readmeMd,$testDatabaseKdbx)
$releaseZip = Join-Path -Path $PSScriptRoot -ChildPath "PowerPass-0.0.0.zip"
Compress-Archive -Path $release -DestinationPath $releaseZip -CompressionLevel Optimal