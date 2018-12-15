function Get-FlexVersion {
	[CmdletBinding(DefaultParameterSetName = "p0",
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial
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

			# minimum required version
			[UInt64]$reqVerUInt64 = $radioObj.ReqVersion

			$reqVer = ($reqVerUInt64 -shr 48 -band 0xFF).tostring() + "." + ($reqVerUInt64 -shr 40 -band 0xFF).tostring() + "." + ($reqVerUInt64 -shr 32 -band 0xFF).tostring() + "." + ($reqVerUInt64 -band 0xFFFF).tostring()

			$psObj = new-object psobject

			$psObj | add-member NoteProperty "Serial" $radioObj.Serial
			$psObj | add-member NoteProperty "Component" RequiredVersion
			$psObj | add-member NoteProperty "Version" $reqVer

			$psObj

			# discovery protocol version
			[UInt64]$discVerUInt64 = $radioObj.DiscoveryProtocolVersion

			$discVer = ($discVerUInt64 -shr 48 -band 0xFF).tostring() + "." + ($discVerUInt64 -shr 40 -band 0xFF).tostring() + "." + ($discVerUInt64 -shr 32 -band 0xFF).tostring() + "." + ($discVerUInt64 -band 0xFFFF).tostring()

			$psObj = new-object psobject

			$psObj | add-member NoteProperty "Serial" $radioObj.Serial
			$psObj | add-member NoteProperty "Component" DiscoveryProtocol
			$psObj | add-member NoteProperty "Version" $discVer

			$psObj

			# other version info
			$verInfo = $radioObj.Versions -split "#"

			foreach ($verStr in $verInfo) {
				$psObj = new-object psobject

				$psObj | add-member NoteProperty "Serial" $radioObj.Serial
				$psObj | add-member NoteProperty "Component" (($verStr -split "=")[0])
				$psObj | add-member NoteProperty "Version" (($verStr -split "=")[-1])

				$psObj
			}

		}
	}

	end { }
}
