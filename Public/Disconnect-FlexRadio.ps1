function Disconnect-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "Default",
		SupportsShouldProcess = $true,
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "Default")]
		[switch]$AllGuiClients
	)

	begin { }

	process {
		if (!$Serial) {
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

			Write-Verbose "Serial: $($radioObj.serial)"

			if (!$radioObj.serial) {
				continue
			}

			if ($AllGuiClients) {
				Write-Verbose "Disconnecting all gui clients ..."

				if ($PSCmdlet.ShouldProcess($radioObj.Serial, "Disconnect all GUI clients")) {
					$radioObj.DisconnectAllGuiClients()
				}

				continue
			}

			Write-Verbose "Disconnecting from radio ..."

			if ($PSCmdlet.ShouldProcess($radioObj.Serial, "Disconnect from Radio")) {
				$radioObj.disconnect()

				Start-Sleep -milliseconds 500

				$count = 0

				while ($count -lt 5) {
					if ($radioObj.Connected -eq $false) {
						Write-Verbose "Radio disconnected."
						$radioObj

						break
					}

					$count++

					Start-Sleep -milliseconds 500
				}
			}
		}
	}

	end { }
}
