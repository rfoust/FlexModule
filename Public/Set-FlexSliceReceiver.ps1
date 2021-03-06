function Set-FlexSliceReceiver {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true,
		ConfirmImpact = "High")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName = "p0", Position = 1, ValueFromPipelineByPropertyName = $true)]
		[int]$Index,

		[Parameter(ParameterSetName = "p0")]
		[string]$AGCMode,

		[Parameter(ParameterSetName = "p0")]
		[int]$AGCOffLevel,

		[Parameter(ParameterSetName = "p0")]
		[int]$AGCThreshold,

		[Parameter(ParameterSetName = "p0")]
		[int]$ANFLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$APFOn,

		[Parameter(ParameterSetName = "p0")]
		[int]$AudioGain,

		[Parameter(ParameterSetName = "p0")]
		[int]$AudioPan,

		[Parameter(ParameterSetName = "p0")]
		[bool]$AutoPan,

		[Parameter(ParameterSetName = "p0")]
		[int]$DaxChannel,

		[Parameter(ParameterSetName = "p0")]
		[string]$DemodMode,

		[Parameter(ParameterSetName = "p0")]
		[int]$DIGLOffset,

		[Parameter(ParameterSetName = "p0")]
		[int]$DIGUOffset,

		[Parameter(ParameterSetName = "p0")]
		[bool]$EqCompBypass,

		[Parameter(ParameterSetName = "p0")]
		[int]$FilterHigh,

		[Parameter(ParameterSetName = "p0")]
		[int]$FilterLow,

		[Parameter(ParameterSetName = "p0")]
		[int]$FMDeviation,

		[Parameter(ParameterSetName = "p0")]
		[double]$FMRepeaterOffsetFreq,

		[Parameter(ParameterSetName = "p0")]
		[string]$FMToneValue,

		[Parameter(ParameterSetName = "p0")]
		[bool]$FmTx1750,

		[Parameter(ParameterSetName = "p0")]
		[double]$Freq,

		[Parameter(ParameterSetName = "p0")]
		[bool]$Lock,

		[Parameter(ParameterSetName = "p0")]
		[bool]$LoopA,

		[Parameter(ParameterSetName = "p0")]
		[bool]$LoopB,

		[Parameter(ParameterSetName = "p0")]
		[bool]$Mute,

		[Parameter(ParameterSetName = "p0")]
		[int]$NBLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$NBOn,

		[Parameter(ParameterSetName = "p0")]
		[int]$NRLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$NROn,

		[Parameter(ParameterSetName = "p0")]
		[string]$Owner,

		[Parameter(ParameterSetName = "p0")]
		[bool]$PlayEnabled,

		[Parameter(ParameterSetName = "p0")]  # todo: what are valid values?
		[string]$RepeaterOffsetDirection,

		[Parameter(ParameterSetName = "p0")]
		[int]$RITFreq,

		[Parameter(ParameterSetName = "p0")]
		[bool]$RITOn,

		[Parameter(ParameterSetName = "p0")]
		[int]$RTTYMark,

		[Parameter(ParameterSetName = "p0")]
		[int]$RTTYShift,

		[Parameter(ParameterSetName = "p0")]
		[string]$RXAnt,

		[Parameter(ParameterSetName = "p0")]
		[int]$SquelchLevel,

		[Parameter(ParameterSetName = "p0")]
		[bool]$SquelchOn,

		[Parameter(ParameterSetName = "p0")]  # todo: what are valud values?
		[string]$ToneMode,

		[Parameter(ParameterSetName = "p0")]
		[bool]$Transmit,

		[Parameter(ParameterSetName = "p0")]
		[int]$TuneStep,

		[Parameter(ParameterSetName = "p0")]
		[string]$TXAnt,

		[Parameter(ParameterSetName = "p0")]
		[double]$TXOffsetFreq,

		[Parameter(ParameterSetName = "p0")]
		[bool]$Wide,

		[Parameter(ParameterSetName = "p0")]
		[int]$XITFreq,

		[Parameter(ParameterSetName = "p0")]
		[bool]$XITOn
	)

	begin { }

	process {
		if (-not $Serial) {
			if ($global:FlexRadios.count -eq 1) {
				$radioObject = $global:FlexRadios[0]
			}
			else {
				throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
			}
		}
		else {
			$radioObject = $global:FlexRadios | Where-Object { $_.serial -eq $Serial }
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

			$slices = get-FlexSliceReceiver -Index:$Index

			foreach ($slice in $slices) {
				# put Lock disable at the top so any requested frequency change on the same command will take effect first.
				if ($PSBoundParameters.ContainsKey('Lock') -and ($Lock -ne $slice.Lock) -and ($Lock -eq $false)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Lock on Slice #$Index")) {
						$slice.set_Lock($Lock)
					}
				}

				if ($PSBoundParameters.ContainsKey('AGCMode') -and ($AGCMode -ne $slice.AGCMode)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AGCMode on Slice #$Index")) {
						$slice.set_AGCMode($AGCMode)
					}
				}

				if ($PSBoundParameters.ContainsKey('AGCOffLevel') -and ($AGCOffLevel -ne $slice.AGCOffLevel)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AGCOffLevel on Slice #$Index")) {
						$slice.set_AGCOffLevel($AGCOffLevel)
					}
				}

				if ($PSBoundParameters.ContainsKey('AGCThreshold') -and ($AGCThreshold -ne $slice.AGCThreshold)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AGCThreshold on Slice #$Index")) {
						$slice.set_AGCThreshold($AGCThreshold)
					}
				}

				if ($PSBoundParameters.ContainsKey('ANFLevel') -and ($ANFLevel -ne $slice.ANFLevel)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify ANFLevel on Slice #$Index")) {
						$slice.set_ANFLevel($ANFLevel)
					}
				}

				if ($PSBoundParameters.ContainsKey('APFOn') -and ($APFOn -ne $slice.APFOn)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify APFOn on Slice #$Index")) {
						$slice.set_APFOn($APFOn)
					}
				}

				if ($PSBoundParameters.ContainsKey('AudioGain') -and ($AudioGain -ne $slice.AudioGain)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AudioGain on Slice #$Index")) {
						$slice.set_AudioGain($AudioGain)
					}
				}

				if ($PSBoundParameters.ContainsKey('AudioPan') -and ($AudioPan -ne $slice.AudioPan)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AudioPan on Slice #$Index")) {
						$slice.set_AudioPan($AudioPan)
					}
				}

				if ($PSBoundParameters.ContainsKey('AutoPan') -and ($AutoPan -ne $slice.AutoPan)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify AutoPan on Slice #$Index")) {
						$slice.set_AutoPan($AutoPan)
					}
				}

				if ($PSBoundParameters.ContainsKey('DaxChannel') -and ($DaxChannel -ne $slice.DaxChannel)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify DaxChannel on Slice #$Index")) {
						$slice.set_DaxChannel($DaxChannel)
					}
				}

				if ($PSBoundParameters.ContainsKey('DemodMode') -and ($DemodMode -ne $slice.DemodMode)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify DemodMode on Slice #$Index")) {
						$slice.set_DemodMode($DemodMode)
					}
				}

				if ($PSBoundParameters.ContainsKey('DIGLOffset') -and ($DIGLOffset -ne $slice.DIGLOffset)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify DIGLOffset on Slice #$Index")) {
						$slice.set_DIGLOffset($DIGLOffset)
					}
				}

				if ($PSBoundParameters.ContainsKey('DIGUOffset') -and ($DIGUOffset -ne $slice.DIGUOffset)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify DIGUOffset on Slice #$Index")) {
						$slice.set_DIGUOffset($DIGUOffset)
					}
				}

				if ($PSBoundParameters.ContainsKey('EqCompBypass') -and ($EqCompBypass -ne $slice.EqCompBypass)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify EqCompBypass on Slice #$Index")) {
						$slice.set_EqCompBypass($EqCompBypass)
					}
				}

				if ($PSBoundParameters.ContainsKey('FilterHigh') -and ($FilterHigh -ne $slice.FilterHigh)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FilterHigh on Slice #$Index")) {
						$slice.set_FilterHigh($FilterHigh)
					}
				}

				if ($PSBoundParameters.ContainsKey('FilterLow') -and ($FilterLow -ne $slice.FilterLow)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FilterLow on Slice #$Index")) {
						$slice.set_FilterLow($FilterLow)
					}
				}

				if ($PSBoundParameters.ContainsKey('FMDeviation') -and ($FMDeviation -ne $slice.FMDeviation)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FMDeviation on Slice #$Index")) {
						$slice.set_FMDeviation($FMDeviation)
					}
				}

				if ($PSBoundParameters.ContainsKey('FMRepeaterOffsetFreq') -and ($FMRepeaterOffsetFreq -ne $slice.FMRepeaterOffsetFreq)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FMRepeaterOffsetFreq on Slice #$Index")) {
						$slice.set_FMRepeaterOffsetFreq($FMRepeaterOffsetFreq)
					}
				}

				if ($PSBoundParameters.ContainsKey('FMToneValue') -and ($FMToneValue -ne $slice.FMToneValue)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FMToneValue on Slice #$Index")) {
						$slice.set_FMToneValue($FMToneValue)
					}
				}

				if ($PSBoundParameters.ContainsKey('FmTx1750') -and ($FmTx1750 -ne $slice.FmTx1750)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify FmTx1750 on Slice #$Index")) {
						$slice.set_FMTX1750($FmTx1750)
					}
				}

				if ($PSBoundParameters.ContainsKey('Freq') -and ($Freq -ne $slice.Freq)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Freq on Slice #$Index")) {
						$slice.set_Freq($Freq)
					}
				}

				if ($PSBoundParameters.ContainsKey('LoopA') -and ($LoopA -ne $slice.LoopA)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify LoopA on Slice #$Index")) {
						$slice.set_LoopA($LoopA)
					}
				}

				if ($PSBoundParameters.ContainsKey('LoopB') -and ($LoopB -ne $slice.LoopB)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify LoopB on Slice #$Index")) {
						$slice.set_LoopB($LoopB)
					}
				}

				if ($PSBoundParameters.ContainsKey('Mute') -and ($Mute -ne $slice.Mute)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Mute on Slice #$Index")) {
						$slice.set_Mute($Mute)
					}
				}

				if ($PSBoundParameters.ContainsKey('NBLevel') -and ($NBLevel -ne $slice.NBLevel)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify NBLevel on Slice #$Index")) {
						$slice.set_NBLevel($NBLevel)
					}
				}

				if ($PSBoundParameters.ContainsKey('NBOn') -and ($NBOn -ne $slice.NBOn)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify NBOn on Slice #$Index")) {
						$slice.set_NBOn($NBOn)
					}
				}

				if ($PSBoundParameters.ContainsKey('NRLevel') -and ($NRLevel -ne $slice.NRLevel)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify NRLevel on Slice #$Index")) {
						$slice.set_NRLevel($NRLevel)
					}
				}

				if ($PSBoundParameters.ContainsKey('NROn') -and ($NROn -ne $slice.NROn)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify NROn on Slice #$Index")) {
						$slice.set_NROn($NROn)
					}
				}

				if ($PSBoundParameters.ContainsKey('Owner') -and ($Owner -ne $slice.Owner)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Owner on Slice #$Index")) {
						$slice.set_Owner($Owner)
					}
				}

				if ($PSBoundParameters.ContainsKey('PlayEnabled') -and ($PlayEnabled -ne $slice.PlayEnabled)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify PlayEnabled on Slice #$Index")) {
						$slice.set_PlayEnabled($PlayEnabled)
					}
				}

				if ($PSBoundParameters.ContainsKey('RepeaterOffsetDirection') -and ($RepeaterOffsetDirection -ne $slice.RepeaterOffsetDirection)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RepeaterOffsetDirection on Slice #$Index")) {
						$slice.set_RepeaterOffsetDirection($RepeaterOffsetDirection)
					}
				}

				if ($PSBoundParameters.ContainsKey('RITFreq') -and ($RITFreq -ne $slice.RITFreq)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RITFreq on Slice #$Index")) {
						$slice.set_RITFreq($RITFreq)
					}
				}

				if ($PSBoundParameters.ContainsKey('RITOn') -and ($RITOn -ne $slice.RITOn)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RITOn on Slice #$Index")) {
						$slice.set_RITOn($RITOn)
					}
				}

				if ($PSBoundParameters.ContainsKey('RTTYMark') -and ($RTTYMark -ne $slice.RTTYMark)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RTTYMark on Slice #$Index")) {
						$slice.set_RTTYMark($RTTYMark)
					}
				}

				if ($PSBoundParameters.ContainsKey('RTTYShift') -and ($RTTYShift -ne $slice.RTTYShift)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RTTYShift on Slice #$Index")) {
						$slice.set_RTTYShift($RTTYShift)
					}
				}

				if ($PSBoundParameters.ContainsKey('RXAnt') -and ($RXAnt -ne $slice.RXAnt)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify RXAnt on Slice #$Index")) {
						$slice.set_RXAnt($RXAnt)
					}
				}

				if ($PSBoundParameters.ContainsKey('SquelchLevel') -and ($SquelchLevel -ne $slice.SquelchLevel)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SquelchLevel on Slice #$Index")) {
						$slice.set_SquelchLevel($SquelchLevel)
					}
				}

				if ($PSBoundParameters.ContainsKey('SquelchOn') -and ($SquelchOn -ne $slice.SquelchOn)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify SquelchOn on Slice #$Index")) {
						$slice.set_SquelchOn($SquelchOn)
					}
				}

				if ($PSBoundParameters.ContainsKey('ToneMode') -and ($ToneMode -ne $slice.ToneMode)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify ToneMode on Slice #$Index")) {
						$slice.set_ToneMode($ToneMode)
					}
				}

				if ($PSBoundParameters.ContainsKey('Transmit') -and ($Transmit -ne $slice.Transmit)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Transmit on Slice #$Index")) {
						$slice.set_Transmit($Transmit)
					}
				}

				if ($PSBoundParameters.ContainsKey('TuneStep') -and ($TuneStep -ne $slice.TuneStep)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TuneStep on Slice #$Index")) {
						$slice.set_TuneStep($TuneStep)
					}
				}

				if ($PSBoundParameters.ContainsKey('TXAnt') -and ($TXAnt -ne $slice.TXAnt)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXAnt on Slice #$Index")) {
						$slice.set_TXAnt($TXAnt)
					}
				}

				if ($PSBoundParameters.ContainsKey('TXOffsetFreq') -and ($TXOffsetFreq -ne $slice.TXOffsetFreq)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify TXOffsetFreq on Slice #$Index")) {
						$slice.set_TXOffsetFreq($TXOffsetFreq)
					}
				}

				if ($PSBoundParameters.ContainsKey('Wide') -and ($Wide -ne $slice.Wide)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Wide on Slice #$Index")) {
						$slice.set_Wide($Wide)
					}
				}

				if ($PSBoundParameters.ContainsKey('XITFreq') -and ($XITFreq -ne $slice.XITFreq)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify XITFreq on Slice #$Index")) {
						$slice.set_XITFreq($XITFreq)
					}
				}

				if ($PSBoundParameters.ContainsKey('XITOn') -and ($XITOn -ne $slice.XITOn)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify XITOn on Slice #$Index")) {
						$slice.set_XITOn($XITOn)
					}
				}

				# put Lock enable at the bottom so any requested frequency change above will take effect first.
				if ($PSBoundParameters.ContainsKey('Lock') -and ($Lock -ne $slice.Lock) -and ($Lock -eq $true)) {
					if ($pscmdlet.ShouldProcess($radioObj.Serial, "Modify Lock on Slice #$Index")) {
						$slice.set_Lock($Lock)
					}
				}
			}
		}
	}

	end { }
}
