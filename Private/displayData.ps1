function displayData ([string]$data) {
	$consoleWidth = $host.ui.rawui.windowsize.width
	$leftPad = 28   # 10 for date/time, 15 for source + padding + extra stuff
	#$dataLength = $data.length
	$maxDataWidth = $consoleWidth - $leftPad - 2    # the 3 is for the " : " in the prefix string, and subtract one for a right pad

	$firstLine = $true
	$dataStringIndex = 0        #starting point
	$processing = $true

	while ($processing) {
		if ($firstLine) {
			if (($maxDataWidth -ge $data.length) -or ($dataStringIndex -gt $data.length)) {
				$outputString = $data
				$processing = $false
			}
			else {
				$outputString = $data.substring($dataStringIndex, $maxDataWidth)
				$dataStringIndex = $dataStringIndex + $maxDataWidth
			}
		}
		else {
			if (($maxDataWidth -ge ($data.length - ($dataStringIndex + 1))) -or ($dataStringIndex -gt $data.length)) {
				$outputString = $data.substring($dataStringIndex, $data.length - ($dataStringIndex))
				$processing = $false
			}
			else {
				$outputString = $data.substring($dataStringIndex, $maxDataWidth)
				$dataStringIndex = $dataStringIndex + $maxDataWidth
			}
		}

		if ($firstLine) {
			write-host $outputString -foregroundcolor gray
			$firstLine = $false
		}
		else {
			write-host (" : ").padleft($leftPad) -foregroundcolor white -nonewline
			write-host $outputString -foregroundcolor gray
		}
	}
}
