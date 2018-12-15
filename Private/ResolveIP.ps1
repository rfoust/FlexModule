$hostcache = @{}  # hashtable to cache hostnames to speed up ResolveIP()

function ResolveIP ($ip) {
	if ($data = $hostcache."$($ip.IPAddressToString)") {
		if ($ip.IPAddressToString -eq $data) {
			[system.net.ipaddress]$ip
		}
		else {
			$data
		}
	}
	else {
		$null, $null, $null, $data = nslookup $ip.IPAddressToString 2>$null

		$data = $data -match "Name:"

		if ($data -match "Name:") {
			$data = $data[0] -replace "Name:\s+", ""
			$hostcache."$($ip.IPAddressToString)" = "$data"
			$data
		}
		else {
			$hostcache."$($ip.IPAddressToString)" = "$($ip.IPAddressToString)"
			$ip
		}
	}
}
