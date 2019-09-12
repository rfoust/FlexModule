function Get-FlexTraffic {
	[CmdletBinding(DefaultParameterSetName = "p0",
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "p0", Position = 1)]
		[string]$LocalIP
	)

	begin { }

	process {
		if (-not $Serial) {
			$radios = get-FlexRadio

			if ($radios.count -eq 1) {
				write-verbose "One FlexRadio found. Using it."
				$Serial = $radios[0].serial
			}
			else {
				throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
			}
		}


		$radioObj = get-FlexRadio -Serial:$serial

		write-verbose "Serial: $($radioObj.serial)"

		if (-not $radioObj.serial) {
			continue
		}

		write-verbose "Radio connected: $($radioObj.connected)"

		displayTime
		displaySource "*"
		write-host "Press ESC to exit the packet sniffer." -foregroundcolor cyan

		<#
        $smartSDRdetected = $false
        $SmartSDRVersion = (get-process | ? { $_.processname -match "SmartSDR" }).productversion

        if ($SmartSDRVersion)
            {
            displayTime
            displaySource "*"
            write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
            $smartSDRdetected = $true
            }
        #>

		$remoteIP = $radioObj.ip

		if (-not $remoteIP) {
			throw "Unable to locate FlexRadio IP address!"
		}

		$fragment = $null
		$fragmentFound = $false

		displayTime
		displaySource "*"
		write-host "Expect packet sniffer delays if a high amount of network traffic is expected." -foregroundcolor cyan

		$pingHash = @{}
		$pingCount = 0

		#get-packet | ? { ($_.source -eq "192.168.1.133" -or $_.destination -eq "192.168.1.133") -and ($_.protocol -eq "TCP")} | % {
		get-flexpacket | Where-Object { $_.Protocol -eq "TCP" -and ($_.Source -eq $remoteIP -or $_.destination -eq $remoteIP) } | ForEach-Object {
			$packet = $_.data

			if (!$packet) {
				continue
			}

			<#
            if ($smartSDRdetected -eq $false)
                {
                $SmartSDRVersion = (get-process | ? { $_.processname -match "SmartSDR" }).productversion
                write-verbose "SmartSDRVersion: $SmartSDRVersion"

                if ($SmartSDRVersion)
                    {
                    displayTime
                    displaySource "*"
                    write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
                    $smartSDRdetected = $true
                    }
                }
            #>

			if ($fragmentFound) {
				$newData = ($packet -split '\n')[0]
				$newDataComplete = $fragment + $newData

				$packet = $packet -replace [regex]::Escape($newData), $newDataComplete

				$fragmentFound = $false
			}

			if ($packet -notmatch '\Z\n') {
				$fragment = "`n" + ($packet -split '\n')[-1]

				if ($fragment -ne "`n") {
					$packet = $packet -replace [regex]::Escape($fragment), ''

					$fragmentFound = $true
				}
			}

			$packet -split '\n' | ForEach-Object { $_ -replace '^\x00*', '' } | Where-Object { $_ -ne "" -and $_ -ne $null } | ForEach-Object {

				$packetdata = $_

				$prefix = $packetdata[0]

				if ($packetdata) {
					[string]$packetSubData = $packetdata.substring(1)
				}

				switch ($prefix) {
					"V" {
						displayTime
						displaySource "Radio"
						write-host "Version: $packetSubData" -foregroundcolor green
						break
					}
					"H" {
						displayTime
						displaySource "Radio"
						write-host "Handle received: [$packetSubData]" -foreground green
						break
					}
					"C" {
						# command sent
						$sequence, $command = $packetSubData.split("|")

						if ($command -match "^ping") {
							$pingHash[$sequence] = get-date
							$pingCount++

							if ($pingCount % 50 -eq 0) {
								displayTime
								displaySource "*"
								displayData "$pingCount keepalive pings have been seen."

								displayTime
								displaySource "*"

								if ($pingHash.count) {
									displayData "$($pingHash.count) unacknowledged ping(s)."
								}
							}

							break
						}

						displayTime
						displaySource "Local"
						displayData "{$sequence} $command"
						break
					}
					"R" {
						$sequence, $command = $packetSubData.split("|")

						if ($pingHash[$sequence]) {
							$pingHash.Remove($sequence)

							break
						}

						displayTime
						displaySource "RadioResponse"

						displayData "{$sequence} $command"
						break
					}
					"S" {
						displayTime
						displaySource "RadioStatus"
						$handle, $command = $packetSubData.split("|")
						displayData "[$handle] $command"
						break
					}
					"M" {
						displayTime
						displaySource "RadioMessage"
						$handle, $command = $packetSubData.split("|")

						#switch ($handle)
						#   {
						#   # decode message number for severity
						#   }
						write-host "$command"
						break
					}
					default {
						displayTime
						displaySource "Fragment"
						displayData "$packetData"
					}
				}
			}
		}
	}

	end { }
}
