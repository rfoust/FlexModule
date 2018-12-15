function displayTime {
	$now = get-date -format "HH:mm:ss"

	write-host "[" -foregroundcolor green -nonewline
	write-host $now -foregroundcolor gray -nonewline
	write-host "]" -foregroundcolor green -nonewline
	# write-host " : " -foregroundcolor white -nonewline
}
