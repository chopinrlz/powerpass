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