#
# Random binary file generator.
#
# Copyright 2023-2026 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
#

param(
	[int]
	$Size
)
$blockSize = 256
$rand = [System.Random]::new()
$total = 0
[byte[]]$data = [System.Array]::CreateInstance( [byte[]], $blockSize )
$path = Join-Path -Path $PSScriptRoot -ChildPath "random.bin"
if( Test-Path $path ) {
	Remove-Item -Path $path -Force
}
$file = [System.IO.File]::OpenWrite( $path )
while( $total -lt $Size ) {
	$rand.NextBytes( $data )
	$file.Write( $data, 0, $data.Length )
	$total += $blockSize
}
$file.Flush()
$file.Close()