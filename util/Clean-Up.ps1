#
# Repo clean up script for post-build cleanup
#
# Copyright 2023-2025 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#

<#
    .SYNOPSIS
    Cleans up files from the build release process and TPM edition binaries.
#>

# Move to the root of the repo and save the caller's path
$callerLocation = Get-Location
Set-Location -Path "$PSScriptRoot/.."

# Declare known files for cleanup
$knownFiles = @(
	"KeePassLib.dll",
	"hash.md",
	"hash.json",
	"powerpass.sln"
)

# Declare known directories for cleanup
$knownPaths = @(
	"release",
	"bin",
	"obj"
)

# Remove all known files for cleanup
$knownFiles | ForEach-Object {
	$knownFile = Join-Path -Path (Get-Location) -ChildPath $_
	if( Test-Path $knownFile ) {
		Remove-Item -Path $knownFile -Force -Verbose
	}
}

# Remove all known directories for cleanup
$knownPaths | ForEach-Object {
	$knownPath = Join-Path -Path (Get-Location) -ChildPath $_
	if( Test-path $knownPath ) {
		Remove-Item -Path $knownPath -Recurse -Force -Verbose
	}
}

# Find any release binaries and delete them
Get-ChildItem -Path (Get-Location) -Filter "PowerPass-*.zip" | Remove-Item -Force -Verbose
Get-ChildItem -Path (Get-Location) -Filter "PowerPass-*.tar.gz" | Remove-Item -Force -Verbose

# Set the location back to the caller's location
Set-Location -Path $callerLocation