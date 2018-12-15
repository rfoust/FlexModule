function Restart-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
		ConfirmImpact = "High")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial
	)

	begin { }

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

			write-verbose "Rebooting radio ..."

			if ($pscmdlet.ShouldProcess($radioObj.Serial, "Reboot Radio")) {
				$radioObj.RebootRadio()
			}
		}
	}

	end { }
}
