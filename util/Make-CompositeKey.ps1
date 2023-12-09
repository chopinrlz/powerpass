if( $PSVersionTable.PSVersion.Major -ne 7 ) {
    throw "This is designed for PowerShell 7"
}
[string]$hostName = & hostname
[string]$userName = & whoami
[string]$macAddress = ""
if( $IsLinux ) {
    $macRegEx = "([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}){1}"
    $mac = & ifconfig | grep -E ether
    if( $mac ) {
        $macAddress = (Select-String -InputObject $mac -Pattern $macRegEx).Matches[0].Value
    } else {
        throw "Could not locate an Ethernet adapter with ifconfig"
    }
} elseif( $IsWindows ) {
    $nics = Get-CimInstance -ClassName "CIM_NetworkAdapter" | ? PhysicalAdapter
    if( $nics ) {
        if( $nics.Count -gt 1 ) {
            $nics = $nics[0]
        }
        $macAddress = $nics.MACAddress
    } else {
        throw "Could not locate an Ethernet adapter with CIM"
    }
} else {
    throw "This script will only support Linux and Windows at the moment"
}
if( -not $hostName ) { throw "No hostname found" }
if( -not $userName ) { throw "No username found" }
if( -not $macAddress ) { throw "No MAC address found" }
$compKey = "$hostName|$userName|$macAddress"
Write-Output "Composite Key: $compKey"
$compKeyBytes = [System.Text.Encoding]::UTF8.GetBytes( $compKey )
Add-Type -AssemblyName "System.Security.Cryptography"
$sha = [System.Security.Cryptography.Sha256]::Create()
$salt = $sha.ComputeHash( $compKeyBytes )
$salt = [System.Convert]::ToBase64String( $salt )
Write-Output "Salt: $salt"