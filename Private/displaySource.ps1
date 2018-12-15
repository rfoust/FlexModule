function displaySource ([string]$source, [int]$pad = 15) {

	$source = $source.padleft($pad)

	switch -wildcard ($source) {
		"*Radio" {
			$foreColor = "magenta"
			break
		}
		"*Local" {
			$foreColor = "cyan"
			break
		}
		"*RadioResponse" {
			$foreColor = "yellow"
			break
		}
		"*RadioStatus" {
			$foreColor = "blue"
			break
		}
		"*RadioMessage" {
			$foreColor = "green"
			break
		}
		"`*" {
			$foreColor = "cyan"
			break
		}
		default {
			$foreColor = "gray"
			break
		}
	}

	write-host $source -foregroundcolor $foreColor -nonewline
	write-host " : " -foregroundcolor  white -nonewline
}
