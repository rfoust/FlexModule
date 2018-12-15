function Get-JwtTokenData {
	[CmdletBinding()]
	Param
	(
		# Param1 help description
		[Parameter(Mandatory = $true)]
		[string] $Token,
		[switch] $Recurse
	)

	if ($Recurse) {
		$decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Token))
		Write-Host("Token") -ForegroundColor Green
		Write-Host($decoded)
		$DecodedJwt = ConvertFrom-JWT -rawToken $decoded
	}
	else {
		$DecodedJwt = ConvertFrom-JWT -rawToken $Token
	}
	Write-Host("Token Values") -ForegroundColor Green
	Write-Host ($DecodedJwt | Select-Object headers, claims | ConvertTo-Json)
	return $DecodedJwt
}
