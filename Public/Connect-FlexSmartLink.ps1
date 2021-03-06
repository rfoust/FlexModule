function Connect-FlexSmartLink {
	[CmdletBinding(DefaultParameterSetName = "p0")]
	param()

	$server = "frtest.auth0.com"
	$client = "4Y9fEIIsVYyQo5u6jr7yBWc4lV5ugC2m"	# SmartLink client ID
	$response_type = "token"
	$redirect_uri = "https://frtest.auth0.com/mobile"
	$scope = @("openid", "offline_access", "email", "given_name", "family_name", "picture")
	$state = -join ((65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object {[char]$_})		# example: "ypfolheqwpezrxdb"
	$device = "FlexModule"

	# windows forms dependencies
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Web

	# create window for embedded browser
	$form = New-Object Windows.Forms.Form
	$form.Width = 400
	$form.Height = 560
	$web = New-Object Windows.Forms.WebBrowser
	$web.Size = $form.ClientSize
	$web.Anchor = "Left,Top,Right,Bottom"
	$form.Controls.Add($web)

	# global for collecting authorization code response
	$Global:redirect_uri = $null

	# add handler for the embedded browser's Navigating event
	$url = "https://$server/authorize?client_id=$client&redirect_uri=$redirect_uri&response_type=$response_type&scope=$($scope -join "%20")&state=$state&device=$device"

	$web.add_Navigated( {
			Write-Verbose "Navigating $($Url)"
			# detect when browser is about to fetch redirect_uri
			#$uri = [uri] $Global:clientreq.redirect_uris[0]
			#$uri = "https://frtest.auth0.com"

			write-verbose "url: $($_.url)"
			write-verbose "authority: $($_.url.authority)"

			write-verbose "url data"
			$_.url | ForEach-Object { write-verbose $_ }

			if ($_.url.pathandquery -match "^/mobile") {
				# collect authorization response in a global
				$Global:redirect = $_.Url
				write-verbose "global redirect: $($global:redirect_uri)"
				# cancel event and close browser window
				$form.DialogResult = "OK"
				$form.Close()
				#$_.Cancel = $true
			}
		})

	$web.Navigate($url)
	# show browser window, waits for window to close
	if ($form.ShowDialog() -ne "OK") {
		Write-Verbose "WebBrowser: Canceled"
		return
	}

	if (-not $Global:redirect) {
		Write-Verbose "WebBrowser: redirect_uri is null"
		return
	}

	$global:jwt = $global:redirect.OriginalString -split "&" | Where-Object { $_ -match "id_token" } | ForEach-Object { $_ -replace "id_token=", "" }
	$global:WanServer = New-Object Flex.Smoothlake.Flexlib.Wanserver
	$global:WanServer.Connect()

	$count = 0
	$connected = $false

	while (($count -le 10) -and !$connected) {
		if ($global:WanServer.IsConnected -eq $true) {
			$connected = $true
		}
		else {
			start-sleep -milliseconds 250
			$count++
		}
	}

	$global:WanListReceivedEvent = Register-ObjectEvent -InputObject ([flex.smoothlake.flexlib.api]) -EventName WanListReceived -Action {Add-FlexWanServer $event}
	#$global:WanRadioConnectReadyEvent = Register-ObjectEvent -InputObject (new-object flex.smoothlake.flexlib.api.wanserver) -EventName WanRadioConnectReady -Action {$global:WanRadioConnectReady = $event.SourceArgs}


	$global:WanServer.SendRegisterApplicationMessageToServer($device, $env:os, $global:jwt)
}
