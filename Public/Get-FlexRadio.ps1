# note: serial number (property name "serial") should be the primary identifier for each radio
# there is a global variable $global:flexradios that will contain all flex radios found
# the various module cmdlets should be able to get/set on that object by finding a matching serial number.
function Get-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "p0")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipeline = $true)]
		[Parameter(ParameterSetName = "p1", Position = 0, ValueFromPipeline = $true)]
		[Parameter(ParameterSetName = "p2", Position = 0, ValueFromPipeline = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "p1")]
		[switch]$LanOnly,

		[Parameter(ParameterSetName = "p2")]
		[switch]$WanOnly
	)

	begin { }

	process {
		$count = 0
		$found = $false

		while (($count -le 10) -and !$found) {
			$global:FlexRadios = @()

			if ((!$global:FlexWanOnly -and !$WanOnly) -or $LanOnly) {
				$global:FlexRadios += [flex.smoothlake.flexlib.api]::RadioList | ForEach-Object { $_ }
			}

			if (!$LanOnly) {
				foreach ($radio in $global:WanFlexRadios) {
					if (($global:FlexRadios).Serial -NotContains $radio.Serial) {
						$global:FlexRadios += $radio
					}
				}
			}

			if (!$global:FlexRadios) {
				write-verbose "No FlexRadios found, retrying ($count of 10) ..."

				start-sleep -milliseconds 250
				$count++
			}
			else {
				$found = $true
			}
		}

		if (!$global:FlexRadios) {
			return
		}

		if ($Serial) {
			$global:FlexRadios | Where-Object { $_.serial -eq $Serial }
		}
		else {
			# using for loop to prevent modified collection exception when using pipeline
			for ($i = 0; $i -lt $global:FlexRadios.count; $i++) {
				$global:FlexRadios[$i]
			}
		}
	}

	end { }
}
