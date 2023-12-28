if( $PSVersionTable.PSVersion.Major -lt 7 ) {
    throw "TPM support is for PowerShell 7"
}
$source = Get-Content "TpmProvider.cs"
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Runtime.InteropServices"
$provider = New-Object "PowerPass.TpmProvider"
$provider.Test()