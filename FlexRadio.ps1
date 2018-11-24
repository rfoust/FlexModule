# FlexRadio.ps1

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

function Disconnect-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
		ConfirmImpact = "Low")]
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

			write-verbose "Disconnecting radio ..."

			if ($pscmdlet.ShouldProcess($radioObj.Serial, "Disconnect from Radio")) {
				$radioObj.disconnect()

				start-sleep -milliseconds 500

				$count = 0

				while ($count -lt 5) {
					if ($radioObj.Connected -eq $false) {
						write-verbose "Radio disconnected."
						$radioObj

						break
					}

					$count++

					start-sleep -milliseconds 500
				}
			}
		}
	}

	end { }
}

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


function Set-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "p0")]
		[bool]$ACCOn,

		[Parameter(ParameterSetName = "p0")]
		[int]$AMCarrierLevel,

		[Parameter(ParameterSetName = "p0")]
		[int]$APFGain,

		[Parameter(ParameterSetName = "p0")]
		[bool]$APFMode,

		[Parameter(ParameterSetName = "p0")]
		[int]$APFQFactor,

		[Parameter(ParameterSetName = "p0")]
		[bool]$BinauralRX,

		[Parameter(ParameterSetName = "p0")]
		[double]$CalFreq,

		[Parameter(ParameterSetName = "p0")]
		[string]$Callsign,

		[Parameter(ParameterSetName = "p0")]
		[int]$CompanderLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CompanderOn,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWBreakIn,

		[Parameter(ParameterSetName = "p0")]
		[int]$CWDelay,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWIambic,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWIambicModeA,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWIambicModeB,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWLEnabled,

		[Parameter(ParameterSetName = "p0")]
		[int]$CWPitch,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWSidetone,

		[Parameter(ParameterSetName = "p0")]
		[int]$CWSpeed,

		[Parameter(ParameterSetName = "p0")]
		[bool]$CWSwapPaddles,

		[Parameter(ParameterSetName = "p0")]
		[int]$DelayTX,

		[Parameter(ParameterSetName = "p0")]
		[string]$DAXOn,

		[Parameter(ParameterSetName = "p0")]
		[int]$FreqErrorPPB,

		[Parameter(ParameterSetName = "p0")]
		[bool]$FullDuplexEnabled,

		[Parameter(ParameterSetName = "p0")]
		[int]$HeadphoneGain,

		[Parameter(ParameterSetName = "p0")]
		[bool]$HeadphoneMute,

		[Parameter(ParameterSetName = "p0")]
		[bool]$HWAlcEnabled,

		[Parameter(ParameterSetName = "p0")]
		[int]$LineoutGain,

		[Parameter(ParameterSetName = "p0")]
		[bool]$LineoutMute,

		[Parameter(ParameterSetName = "p0")]
		[bool]$MetInRX,

		[Parameter(ParameterSetName = "p0")]
		[bool]$MicBias,

		[Parameter(ParameterSetName = "p0")]
		[bool]$MicBoost,

		[Parameter(ParameterSetName = "p0")]
		[int]$MicLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$Mox,

		[Parameter(ParameterSetName = "p0")]
		[string]$Nickname,

		[Parameter(ParameterSetName = "p0")]
		[bool]$RemoteOnEnabled,

		[Parameter(ParameterSetName = "p0")]
		[int]$RFPower,

		[Parameter(ParameterSetName = "p0")]
		[string]$Screensaver,

		[Parameter(ParameterSetName = "p0")]
		[bool]$ShowTxInWaterfall,

		[Parameter(ParameterSetName = "p0")]
		[bool]$SimpleVOXEnable,

		[Parameter(ParameterSetName = "p0")]
		[int]$SimpleVOXLevel,

		[Parameter(ParameterSetName = "p0")]
		[int]$SimpleVOXDelay,

		[Parameter(ParameterSetName = "p0")]
		[bool]$SnapTune,

		[Parameter(ParameterSetName = "p0")]
		[bool]$SpeechProcessorEnable,

		[Parameter(ParameterSetName = "p0")]
		[uint32]$SpeechProcessorLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$SSBPeakControlEnable,

		[Parameter(ParameterSetName = "p0")]
		[bool]$StartOffsetEnabled,

		[Parameter(ParameterSetName = "p0")]
		[bool]$SyncCWX,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TNFEnabled,

		[Parameter(ParameterSetName = "p0")]
		[int]$TunePower,

		[Parameter(ParameterSetName = "p0")]
		[int]$TXCWMonitorGain,

		[Parameter(ParameterSetName = "p0")]
		[int]$TXSBMonitorGain,

		[Parameter(ParameterSetName = "p0")]
		[int]$TXCWMonitorPan,

		[Parameter(ParameterSetName = "p0")]
		[int]$TXSBMonitorPan,

		[Parameter(ParameterSetName = "p0")]
		[int]$TXFilterLow,

		[Parameter(ParameterSetName = "p0")]
		[int]$TXFilterHigh,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TXMonitor,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TXReqACCEnabled,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TXReqACCPolarity,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TXReqRCAEnabled,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TXReqRCAPolarity,

		[Parameter(ParameterSetName = "p0")]
		[bool]$TXTune
	)

	begin { }

	process {
		if (-not $Serial) {
			if ($global:FlexRadios.count -eq 1) {
				write-verbose "One FlexRadio found. Using it."
				$serial = $global:FlexRadios[0].serial
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

			write-verbose "Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false) {
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
			}

			if ($PSBoundParameters.ContainsKey('AccOn') -and ($ACCOn -ne $radioObj.AccOn)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AccOn")) {
					$radioObj.set_AccOn($AccOn)
				}
			}

			if ($PSBoundParameters.ContainsKey('AMCarrierLevel') -and ($AMCarrierLevel -ne $radioObj.AMCarrierLevel)) {
				if ($AMCarrierLevel -lt 0) { $AMCarrierLevel = 0 }
				if ($AMCarrierLevel -gt 100) { $AMCarrierLevel = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AMCarrierLevel")) {
					$radioObj.set_AMCarrierLevel($AMCarrierLevel)
				}
			}

			if ($PSBoundParameters.ContainsKey('APFGain') -and ($APFGain -ne $radioObj.APFGain)) {
				if ($APFGain -lt 0) { $APFGain = 0 }
				if ($APFGain -gt 100) { $APFGain = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify APFGain")) {
					$radioObj.set_APFGain($APFGain)
				}
			}

			if ($PSBoundParameters.ContainsKey('APFMode') -and ($APFMode -ne $radioObj.APFMode)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify APFMode")) {
					$radioObj.set_APFMode($APFMode)
				}
			}

			if ($PSBoundParameters.ContainsKey('APFQFactor') -and ($APFQFactor -ne $radioObj.APFQFactor)) {
				if ($APFQFactor -lt 0) { $APFQFactor = 0 }
				if ($APFQFactor -gt 33) { $APFQFactor = 33 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify APFQFactor")) {
					$radioObj.set_APFQFactor($APFQFactor)
				}
			}

			if ($PSBoundParameters.ContainsKey('BinauralRX') -and ($BinauralRX -ne $radioObj.BinauralRX)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify BinauralRX")) {
					$radioObj.set_BinauralRX($BinauralRX)
				}
			}

			if ($PSBoundParameters.ContainsKey('CalFreq') -and ($CalFreq -ne $radioObj.CalFreq)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CalFreq")) {
					$radioObj.set_CalFreq($CalFreq)
				}
			}

			if ($PSBoundParameters.ContainsKey('Callsign') -and ($Callsign -ne $radioObj.Callsign)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Callsign")) {
					$radioObj.set_Callsign($Callsign)
				}
			}

			if ($PSBoundParameters.ContainsKey('CompanderLevel') -and ($CompanderLevel -ne $radioObj.CompanderLevel)) {
				if ($CompanderLevel -lt 0) { $CompanderLevel = 0 }
				if ($CompanderLevel -gt 100) { $CompanderLevel = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CompanderLevel")) {
					$radioObj.set_CompanderLevel($CompanderLevel)
				}
			}

			if ($PSBoundParameters.ContainsKey('CompanderOn') -and ($CompanderOn -ne $radioObj.CompanderOn)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CompanderOn")) {
					$radioObj.set_CompanderOn($CompanderOn)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWBreakIn') -and ($CWBreakIn -ne $radioObj.CWBreakIn)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWBreakIn")) {
					$radioObj.set_CWBreakIn($CWBreakIn)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWDelay') -and ($CWDelay -ne $radioObj.CWDelay)) {
				if ($CWDelay -lt 0) { $CWDelay = 0 }
				if ($CWDelay -gt 2000) { $CWDelay = 2000 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWDelay")) {
					$radioObj.set_CWDelay($CWDelay)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWIambic') -and ($CWIambic -ne $radioObj.CWIambic)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWIambic")) {
					$radioObj.set_CWIambic($CWIambic)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWIambicModeA') -and ($CWIambicModeA -ne $radioObj.CWIambicModeA)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWIambicModeA")) {
					$radioObj.set_CWIambicModeA($CWIambicModeA)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWIambicModeB') -and ($CWIambicModeB -ne $radioObj.CWIambicModeB)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWIambicModeB")) {
					$radioObj.set_CWIambicModeB($CWIambicModeB)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWLEnabled') -and ($CWLEnabled -ne $radioObj.CWLEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWL_Enabled")) {
					$radioObj.set_CWL_Enabled($CWLEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWPitch') -and ($CWPitch -ne $radioObj.CWPitch)) {
				if ($CWPitch -lt 100) { $CWPitch = 100 }
				if ($CWPitch -gt 6000) { $CWPitch = 6000 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWPitch")) {
					$radioObj.set_CWPitch($CWPitch)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWSpeed') -and ($CWSpeed -ne $radioObj.CWSpeed)) {
				if ($CWSpeed -lt 5) { $CWSpeed = 5 }
				if ($CWSpeed -gt 100) { $CWSpeed = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWSpeed")) {
					$radioObj.set_CWSpeed($CWSpeed)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWSidetone') -and ($CWSidetone -ne $radioObj.CWSidetone)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWSidetone")) {
					$radioObj.set_CWSidetone($CWSidetone)
				}
			}

			if ($PSBoundParameters.ContainsKey('CWSwapPaddles') -and ($CWSwapPaddles -ne $radioObj.CWSwapPaddles)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify CWSwapPaddles")) {
					$radioObj.set_CWSwapPaddles($CWSwapPaddles)
				}
			}

			if ($PSBoundParameters.ContainsKey('DelayTX') -and ($DelayTX -ne $radioObj.DelayTX)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify DelayTX")) {
					$radioObj.set_DelayTX($DelayTX)
				}
			}

			if ($PSBoundParameters.ContainsKey('DAXOn') -and ($DAXOn -ne $radioObj.DAXOn)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify DAXOn")) {
					$radioObj.set_DAXOn($DAXOn)
				}
			}

			if ($PSBoundParameters.ContainsKey('FreqErrorPPB') -and ($FreqErrorPPB -ne $radioObj.FreqErrorPPB)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FreqErrorPPB")) {
					$radioObj.set_FreqErrorPPB($FreqErrorPPB)
				}
			}

			if ($PSBoundParameters.ContainsKey('FullDuplexEnabled') -and ($FullDuplexEnabled -ne $radioObj.FullDuplexEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FullDuplexEnabled")) {
					$radioObj.set_FullDuplexEnabled($FullDuplexEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('HeadphoneGain') -and ($HeadphoneGain -ne $radioObj.HeadphoneGain)) {
				if ($HeadphoneGain -lt 0) { $HeadphoneGain = 0 }
				if ($HeadphoneGain -gt 100) { $HeadphoneGain = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify HeadphoneGain")) {
					$radioObj.set_HeadphoneGain($HeadphoneGain)
				}
			}

			if ($PSBoundParameters.ContainsKey('HeadphoneMute') -and ($HeadphoneMute -ne $radioObj.HeadphoneMute)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify HeadphoneMute")) {
					$radioObj.set_HeadphoneMute($HeadphoneMute)
				}
			}

			if ($PSBoundParameters.ContainsKey('HWAlcEnabled') -and ($HWAlcEnabled -ne $radioObj.HWAlcEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify HWAlcEnabled")) {
					$radioObj.set_HWAlcEnabled($HWAlcEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('LineoutGain') -and ($LineoutGain -ne $radioObj.LineoutGain)) {
				if ($LineoutGain -lt 0) { $LineoutGain = 0 }
				if ($LineoutGain -gt 100) { $LineoutGain = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify LineoutGain")) {
					$radioObj.set_LineoutGain($LineoutGain)
				}
			}

			if ($PSBoundParameters.ContainsKey('LineoutMute') -and ($LineoutMute -ne $radioObj.LineoutMute)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify LineoutMute")) {
					$radioObj.set_LineoutMute($LineoutMute)
				}
			}

			if ($PSBoundParameters.ContainsKey('MetInRX') -and ($MetInRX -ne $radioObj.MetInRX)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify MetInRX")) {
					$radioObj.set_MetInRX($MetInRX)
				}
			}

			if ($PSBoundParameters.ContainsKey('MicBias') -and ($MicBias -ne $radioObj.MicBias)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify MicBias")) {
					$radioObj.set_MicBias($MicBias)
				}
			}

			if ($PSBoundParameters.ContainsKey('MicBoost') -and ($MicBoost -ne $radioObj.MicBoost)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify MicBoost")) {
					$radioObj.set_MicBoost($MicBoost)
				}
			}

			if ($PSBoundParameters.ContainsKey('MicLevel') -and ($MicLevel -ne $radioObj.MicLevel)) {
				if ($MicLevel -lt 0) { $MicLevel = 0 }
				if ($MicLevel -gt 100) { $MicLevel = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify MicLevel")) {
					$radioObj.set_MicLevel($MicLevel)
				}
			}

			if ($PSBoundParameters.ContainsKey('Mox') -and ($Mox -ne $radioObj.Mox)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Mox")) {
					$radioObj.set_Mox($Mox)
				}
			}

			if ($PSBoundParameters.ContainsKey('Nickname') -and ($Nickname -ne $radioObj.Nickname)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Nickname")) {
					$radioObj.set_Nickname($Nickname)
				}
			}

			if ($PSBoundParameters.ContainsKey('RemoteOnEnabled') -and ($RemoteOnEnabled -ne $radioObj.RemoteOnEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RemoteOnEnabled")) {
					$radioObj.set_RemoteOnEnabled($RemoteOnEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('RFPower') -and ($RFPower -ne $radioObj.RFPower)) {
				if ($RFPower -lt 0) { $RFPower = 0 }
				if ($RFPower -gt 100) { $RFPower = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RFPower")) {
					$radioObj.set_RFPower($RFPower)
				}
			}

			if ($PSBoundParameters.ContainsKey('Screensaver') -and ($Screensaver -ne $radioObj.Screensaver)) {
				if (($Screensaver -ne "name") -and ($Screensaver -ne "callsign")) {
					throw "Valid options for Screensaver are 'name' and 'callsign'."
				}

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Screensaver")) {
					$radioObj.set_Screensaver($Screensaver)
				}
			}

			if ($PSBoundParameters.ContainsKey('ShowTxInWaterfall') -and ($ShowTxInWaterfall -ne $radioObj.ShowTxInWaterfall)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify ShowTxInWaterfall")) {
					$radioObj.set_ShowTxInWaterfall($ShowTxInWaterfall)
				}
			}

			if ($PSBoundParameters.ContainsKey('SimpleVOXEnable') -and ($SimpleVOXEnable -ne $radioObj.SimpleVOXEnable)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SimpleVOXEnable")) {
					$radioObj.set_SimpleVOXEnable($SimpleVOXEnable)
				}
			}

			if ($PSBoundParameters.ContainsKey('SimpleVOXLevel') -and ($SimpleVOXLevel -ne $radioObj.SimpleVOXLevel)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SimpleVOXLevel")) {
					$radioObj.set_SimpleVOXLevel($SimpleVOXLevel)
				}
			}

			if ($PSBoundParameters.ContainsKey('SimpleVOXDelay') -and ($SimpleVOXDelay -ne $radioObj.SimpleVOXDelay)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SimpleVOXDelay")) {
					$radioObj.set_SimpleVOXDelay($SimpleVOXDelay)
				}
			}

			if ($PSBoundParameters.ContainsKey('SnapTune') -and ($SnapTune -ne $radioObj.SnapTune)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SnapTune")) {
					$radioObj.set_SnapTune($SnapTune)
				}
			}

			if ($PSBoundParameters.ContainsKey('SpeechProcessorEnable') -and ($SpeechProcessorEnable -ne $radioObj.SpeechProcessorEnable)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SpeechProcessorEnable")) {
					$radioObj.set_SpeechProcessorEnable($SpeechProcessorEnable)
				}
			}

			if ($PSBoundParameters.ContainsKey('SpeechProcessorLevel') -and ($SpeechProcessorLevel -ne $radioObj.SpeechProcessorLevel)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SpeechProcessorLevel")) {
					$radioObj.set_SpeechProcessorLevel($SpeechProcessorLevel)
				}
			}

			if ($PSBoundParameters.ContainsKey('SSBPeakControlEnable') -and ($SSBPeakControlEnable -ne $radioObj.SSBPeakControlEnable)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SSBPeakControlEnable")) {
					$radioObj.set_SSBPeakControlEnable($SSBPeakControlEnable)
				}
			}

			if ($PSBoundParameters.ContainsKey('StartOffsetEnabled') -and ($StartOffsetEnabled -ne $radioObj.StartOffsetEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify StartOffsetEnabled")) {
					$radioObj.set_StartOffsetEnabled($StartOffsetEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('SyncCWX') -and ($SyncCWX -ne $radioObj.SyncCWX)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SyncCWX")) {
					$radioObj.set_SyncCWX($SyncCWX)
				}
			}

			if ($PSBoundParameters.ContainsKey('TNFEnabled') -and ($TNFEnabled -ne $radioObj.TNFEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TNFEnabled")) {
					$radioObj.set_TNFEnabled($TNFEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('TunePower') -and ($TunePower -ne $radioObj.TunePower)) {
				if ($TunePower -lt 0) { $TunePower = 0 }
				if ($TunePower -gt 100) { $TunePower = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TunePower")) {
					$radioObj.set_TunePower($TunePower)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXMonitor') -and ($TXMonitor -ne $radioObj.TXMonitor)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXMonitor")) {
					$radioObj.set_TXMonitor($TXMonitor)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXCWMonitorGain') -and ($TXCWMonitorGain -ne $radioObj.TXCWMonitorGain)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXCWMonitorGain")) {
					$radioObj.set_TXCWMonitorGain($TXCWMonitorGain)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXSBMonitorGain') -and ($TXSBMonitorGain -ne $radioObj.TXSBMonitorGain)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXSBMonitorGain")) {
					$radioObj.set_TXSBMonitorGain($TXSBMonitorGain)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXCWMonitorPan') -and ($TXCWMonitorPan -ne $radioObj.TXCWMonitorPan)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXCWMonitorPan")) {
					$radioObj.set_TXCWMonitorPan($TXCWMonitorPan)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXSBMonitorPan') -and ($TXSBMonitorPan -ne $radioObj.TXSBMonitorPan)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXSBMonitorPan")) {
					$radioObj.set_TXSBMonitorPan($TXSBMonitorPan)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXFilterLow') -and ($TXFilterLow -ne $radioObj.TXFilterLow)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXFilterLow")) {
					$radioObj.set_TXFilterLow($TXFilterLow)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXFilterHigh') -and ($TXFilterHigh -ne $radioObj.TXFilterHigh)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXFilterHigh")) {
					$radioObj.set_TXFilterHigh($TXFilterHigh)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXReqACCEnabled') -and ($TXReqACCEnabled -ne $radioObj.TXReqACCEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXReqACCEnabled")) {
					$radioObj.set_TXReqACCEnabled($TXReqACCEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXReqACCPolarity') -and ($TXReqACCPolarity -ne $radioObj.TXReqACCPolarity)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXReqACCPolarity")) {
					$radioObj.set_TXReqACCPolarity($TXReqACCPolarity)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXReqRCAEnabled') -and ($TXReqRCAEnabled -ne $radioObj.TXReqRCAEnabled)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXReqRCAEnabled")) {
					$radioObj.set_TXReqRCAEnabled($TXReqRCAEnabled)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXReqRCAPolarity') -and ($TXReqRCAPolarity -ne $radioObj.TXReqRCAPolarity)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXReqRCAPolarity")) {
					$radioObj.set_TXReqRCAPolarity($TXReqRCAPolarity)
				}
			}

			if ($PSBoundParameters.ContainsKey('TXTune') -and ($TXTune -ne $radioObj.TXTune)) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXTune")) {
					$radioObj.set_TXTune($TXTune)
				}
			}
		}
	}

	end { }
}

function Enable-FlexTNF {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
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

			if ($radioObj.TNFEnabled -eq $false) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Enable TNF")) {
					$radioObj.set_TNFEnabled($true)
				}
			}
		}
	}

	end { }
}

function Disable-FlexTNF {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
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

			if ($radioObj.TNFEnabled -eq $true) {
				if ($pscmdlet.ShouldProcess($radioObj.Serial, "Disable TNF")) {
					$radioObj.set_TNFEnabled($false)
				}
			}
		}
	}

	end { }
}

function Install-FlexGPS {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
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

			if ($pscmdlet.ShouldProcess($radioObj.Serial, "Install GPS")) {
				$radioObj.GPSInstall()
			}
		}
	}

	end { }
}

function Uninstall-FlexGPS {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
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

			if ($pscmdlet.ShouldProcess($radioObj.Serial, "Uninstall GPS")) {
				$radioObj.GPSUninstall()
			}
		}
	}
	end { }
}