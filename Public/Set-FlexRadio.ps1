function Set-FlexRadio {
	[CmdletBinding(DefaultParameterSetName = "Default",
		SupportsShouldProcess = $true,
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "Default")]
		[bool]$ACCOn,

		[Parameter(ParameterSetName = "Default")]
		[int]$AMCarrierLevel,

		[Parameter(ParameterSetName = "Default")]
		[int]$APFGain,

		[Parameter(ParameterSetName = "Default")]
		[bool]$APFMode,

		[Parameter(ParameterSetName = "Default")]
		[int]$APFQFactor,

		[Parameter(ParameterSetName = "Default")]
		[bool]$BinauralRX,

		[Parameter(ParameterSetName = "Default")]
		[double]$CalFreq,

		[Parameter(ParameterSetName = "Default")]
		[string]$Callsign,

		[Parameter(ParameterSetName = "Default")]
		[int]$CompanderLevel,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CompanderOn,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWBreakIn,

		[Parameter(ParameterSetName = "Default")]
		[int]$CWDelay,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWIambic,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWIambicModeA,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWIambicModeB,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWLEnabled,

		[Parameter(ParameterSetName = "Default")]
		[int]$CWPitch,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWSidetone,

		[Parameter(ParameterSetName = "Default")]
		[int]$CWSpeed,

		[Parameter(ParameterSetName = "Default")]
		[bool]$CWSwapPaddles,

		[Parameter(ParameterSetName = "Default")]
		[int]$DelayTX,

		[Parameter(ParameterSetName = "Default")]
		[string]$DAXOn,

		[Parameter(ParameterSetName = "Default")]
		[int]$FreqErrorPPB,

		[Parameter(ParameterSetName = "Default")]
		[bool]$FullDuplexEnabled,

		[Parameter(ParameterSetName = "Default")]
		[int]$HeadphoneGain,

		[Parameter(ParameterSetName = "Default")]
		[bool]$HeadphoneMute,

		[Parameter(ParameterSetName = "Default")]
		[bool]$HWAlcEnabled,

		[Parameter(ParameterSetName = "Default")]
		[int]$LineoutGain,

		[Parameter(ParameterSetName = "Default")]
		[bool]$LineoutMute,

		[Parameter(ParameterSetName = "Default")]
		[bool]$MetInRX,

		[Parameter(ParameterSetName = "Default")]
		[bool]$MicBias,

		[Parameter(ParameterSetName = "Default")]
		[bool]$MicBoost,

		[Parameter(ParameterSetName = "Default")]
		[int]$MicLevel,

		[Parameter(ParameterSetName = "Default")]
		[bool]$Mox,

		[Parameter(ParameterSetName = "Default")]
		[string]$Nickname,

		[Parameter(ParameterSetName = "Default")]
		[bool]$RemoteOnEnabled,

		[Parameter(ParameterSetName = "Default")]
		[int]$RFPower,

		[Parameter(ParameterSetName = "Default")]
		[string]$Screensaver,

		[Parameter(ParameterSetName = "Default")]
		[bool]$ShowTxInWaterfall,

		[Parameter(ParameterSetName = "Default")]
		[bool]$SimpleVOXEnable,

		[Parameter(ParameterSetName = "Default")]
		[int]$SimpleVOXLevel,

		[Parameter(ParameterSetName = "Default")]
		[int]$SimpleVOXDelay,

		[Parameter(ParameterSetName = "Default")]
		[bool]$SnapTune,

		[Parameter(ParameterSetName = "Default")]
		[bool]$SpeechProcessorEnable,

		[Parameter(ParameterSetName = "Default")]
		[uint32]$SpeechProcessorLevel,

		[Parameter(ParameterSetName = "Default")]
		[bool]$SSBPeakControlEnable,

		[Parameter(ParameterSetName = "Default")]
		[bool]$StartOffsetEnabled,

		[Parameter(ParameterSetName = "Default")]
		[bool]$SyncCWX,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TNFEnabled,

		[Parameter(ParameterSetName = "Default")]
		[int]$TunePower,

		[Parameter(ParameterSetName = "Default")]
		[int]$TXCWMonitorGain,

		[Parameter(ParameterSetName = "Default")]
		[int]$TXSBMonitorGain,

		[Parameter(ParameterSetName = "Default")]
		[int]$TXCWMonitorPan,

		[Parameter(ParameterSetName = "Default")]
		[int]$TXSBMonitorPan,

		[Parameter(ParameterSetName = "Default")]
		[int]$TXFilterLow,

		[Parameter(ParameterSetName = "Default")]
		[int]$TXFilterHigh,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TXMonitor,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TXReqACCEnabled,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TXReqACCPolarity,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TXReqRCAEnabled,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TXReqRCAPolarity,

		[Parameter(ParameterSetName = "Default")]
		[bool]$TXTune
	)

	begin { }

	process {
		if (-not $Serial) {
			if ($global:FlexRadios.count -eq 1) {
				Write-Verbose "[Set-FlexRadio] One FlexRadio found. Using it."
				$serial = $global:FlexRadios[0].serial
			}
			else {
				throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
			}
		}

		foreach ($radio in $Serial) {
			$radioObj = $global:FlexRadios | Where-Object { $_.serial -eq $Serial }

			Write-Verbose "[Set-FlexRadio] Serial: $($radioObj.serial)"

			if (-not $radioObj.serial) {
				continue
			}

			Write-Verbose "[Set-FlexRadio] Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false) {
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use Connect-FlexRadio to establish a new connection."
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
