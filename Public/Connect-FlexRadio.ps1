function Connect-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial
	)

	begin {
		# Initialize radio list
		if (!$Serial -and !$global:FlexRadios) {
			Get-FlexRadio | Out-Null
		}
	}

	process {
		if (-not $Serial) {
			if ($global:FlexRadios.count -eq 1) {
				write-verbose "One FlexRadio found. Using it."
				$Serial = $global:FlexRadios[0].serial
			}
			else {
				throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
			}
		}

		foreach ($radio in $Serial) {
			$radioObj = $global:FlexRadios | Where-Object { $_.serial -eq $Serial }

			write-verbose "Serial: $($radioObj.serial)"

			if (-not $radioObj.serial) {
				continue
			}

			if ($pscmdlet.ShouldProcess($radioObj.Serial, "Connect to Radio")) {
				$result = $radioObj.connect()

				if ($result -eq $false) {
					write-warning "$($radioObj.serial) : Connect() result was False, unable to connect to radio."
				}
				else {
					$count = 0

					while ($count -lt 5) {
						if ($radioObj.Connected -eq $true) {
							$radioObj

							break
						}

						$count++

						start-sleep -milliseconds 250
					}
				}
			}
		}
	}

	end { }
}
