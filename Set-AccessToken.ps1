$accessTokenFile = Join-Path -Path $PSScriptRoot -ChildPath "access-token"
if( Test-Path $accessTokenFile ) {
	$accessToken = Get-Content $accessTokenFile -Raw
	if( $accessToken ) {
		$url = "https://chopinrlz:$accessToken@github.com/chopinrlz/powerpass.git"
		$a = Read-Host "You are about to set the Github URL to: $url (n/Y) "
		if( $a -ne 'y' ) {
			exit
		} else {
			& git @('remote','set-url','origin',$url)
		}
	} else {
		throw "Empty access token file"
	}
} else {
	throw "No access token file"
}