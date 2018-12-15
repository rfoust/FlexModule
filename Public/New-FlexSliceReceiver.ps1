function New-FlexSliceReceiver {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		# panadapter StreamID to create the slice on.
		[Parameter(ParameterSetName = "p0", Position = 1, ValueFromPipelineByPropertyName = $true)]
		[uint32]$StreamID,

		[Parameter(ParameterSetName = "p0", Position = 2, ValueFromPipelineByPropertyName = $true)]
		[string]$Mode = "LSB"
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

		foreach ($radio in $Serial) {
			$radioObj = get-FlexRadio -Serial:$radio

			write-verbose "Serial: $($radioObj.serial)"

			if (-not $radioObj.serial) {
				continue
			}

			write-verbose "Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false) {
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
			}

			$panadapters = get-FlexPanadapter -StreamID:$StreamID

			foreach ($panadapter in $panadapters) {
				if ($panadapter.StreamID) {
					$newSlice = $null

					if ($radioObj.SlicesRemaining -le 0) {
						throw "All slice receivers are already active!"
					}

					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Create Slice on Pan #$($panadapter.StreamID)")) {
						$newSlice = $radioObj.CreateSlice($panadapter, $mode)

						$newSlice.RequestSliceFromRadio()

						while ($newSlice.RadioAck -ne $true) {
							start-sleep -milliseconds 250
						}

						$newSlice
					}
				}
			}
		}
	}

	end { }
}
