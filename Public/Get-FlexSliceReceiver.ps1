function Get-FlexSliceReceiver {
	[CmdletBinding(DefaultParameterSetName = "Active")]

	param(
		[Parameter(ParameterSetName = "Active", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[Parameter(ParameterSetName = "Inactive", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Letter,

		[Parameter(ParameterSetName = "Active", ValueFromPipelineByPropertyName = $true)]
		[Parameter(ParameterSetName = "Inactive", ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "Active", ValueFromPipelineByPropertyName = $true)]
		[Parameter(ParameterSetName = "Inactive", ValueFromPipelineByPropertyName = $true)]
		[int]$Index,

		[Parameter(ParameterSetName = "Active")]
		[switch]$Active,

		[Parameter(ParameterSetName = "Inactive")]
		[switch]$Inactive
	)

	begin { }

	process {
		if (-not $Serial) {
			$radios = Get-FlexRadio

			if ($radios.count -eq 1) {
				Write-Verbose "[Get-FlexSliceReceiver] One FlexRadio found. Using it."
				$Serial = $radios[0].serial
			}
			else {
				throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
			}
		}

		foreach ($radio in $Serial) {
			$radioObj = Get-FlexRadio -Serial:$radio

			Write-Verbose "[Get-FlexSliceReceiver] Serial: $($radioObj.serial)"

			if (-not $radioObj.serial) {
				continue
			}

			Write-Verbose "[Get-FlexSliceReceiver] Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false) {
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use Connect-FlexRadio to establish a new connection."
			}

			if (-not $radioObj.slicelist) {
				Write-Warning "[Get-FlexSliceReceiver] No slices found! SmartSDR may not be running."
			}

			$slices = $null

			if ($PSBoundParameters.ContainsKey('Index') -and ($Index -ge 0)) {
				$slices = $radioObj.SliceList | Where-Object { $_.index -eq $Index }
			}
			elseif ($PSBoundParameters.ContainsKey('Letter')) {
				$slices = $radioObj.SliceList | Where-Object { $_.Letter -eq $Letter }
			}
			else {
				$slices = $radioObj.SliceList | Sort-Object Letter
			}

			if ($PSBoundParameters.ContainsKey('Active')) {
				$slices = $slices | Where-Object { $_.Active -eq $true }
			}
			elseif ($PSBoundParameters.ContainsKey('Inactive')) {
				$slices = $slices | Where-Object { $_.Active -eq $false }
			}

			$slices
		}
	}

	end { }
}
