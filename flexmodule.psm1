
. $PSScriptRoot\get-packet.ps1
. $PSScriptRoot\FlexRadio.ps1
. $PSScriptRoot\FlexPacket.ps1
. $PSScriptRoot\FlexLib.ps1
. $PSScriptRoot\FlexBackup.ps1
. $PSScriptRoot\FlexMemory.ps1

# todo: send "exit reboot" to reboot radio.

import-flexlib



function get-FlexSliceReceiver
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial
		)

	begin { }

	process 
		{
		if (-not $Serial)
			{
			if ($global:FlexRadios.count -eq 1)
				{
				write-verbose "One FlexRadio found. Using it."
				$Serial = $global:FlexRadios[0].serial
				}
			else
				{
			    throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
				}
			}

		foreach ($radio in $Serial)
			{
			$radioObj = $global:FlexRadios | ? { $_.serial -eq $Serial }

			write-verbose "Serial: $($radioObj.serial)"

			if (-not $radioObj.serial)
				{
				continue
				}
			
			write-verbose "Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false)
				{
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
				}

			if (-not $radioObj.slicelist)
				{
				write-warning "No slices found! SmartSDR may not be running."
				}

			$radioObj.slicelist
			}
		}

	end { }
	}

function get-FlexPanadapter
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial
		)

	begin { }

	process 
		{
		if (-not $Serial)
			{
			if ($global:FlexRadios.count -eq 1)
				{
				write-verbose "One FlexRadio found. Using it."
				$Serial = $global:FlexRadios[0].serial
				}
			else
				{
			    throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
				}
			}

		foreach ($radio in $Serial)
			{
			$radioObj = $global:FlexRadios | ? { $_.serial -eq $Serial }

			write-verbose "Serial: $($radioObj.serial)"

			if (-not $radioObj.serial)
				{
				continue
				}
			
			write-verbose "Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false)
				{
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
				}

			if (-not $radioObj.panadapterlist)
				{
				write-warning "No panadapters found! SmartSDR may not be running."
				}

			$radioObj.panadapterlist
			}
		}

	end { }
	}

function set-FlexSliceReceiver
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName="p0")]
		[bool]$Lock

		)

	begin { }

	process
		{
		if (-not $Serial)
			{
			if ($global:FlexRadios.count -eq 1)
				{
				$radioObject = $global:FlexRadios[0]
				}
			else
				{
			    throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
				}
			}
		else
			{
		    $radioObject = $global:FlexRadios | ? { $_.serial -eq $Serial }
			}

		foreach ($radio in $Serial)
			{
			if ($radio -eq $null)
				{
				continue
				}

			if ($radio.Connected -eq $false)
				{
				throw "Not connected to $($radio.model): $($radio.serial). Use connect-flexradio or get-flexradio | connect-flexradio to establish a new connection."
				}

			if ($PSBoundParameters.ContainsKey('Lock') -and ($Lock -ne $radio.Lock))
				{
				$radio.set_Lock($Lock)
				}
			}
		}

	end { }
	}

# this function needs work
function set-FlexPanadapter
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=1, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject,

		[Parameter(ParameterSetName="p0",Position=0)]
		[bool]$ACCOn

		)

	begin { }

	process
		{
		foreach ($radio in $RadioObject)
			{
			if ($radio -eq $null)
				{
				continue
				}

			if ($radio.Connected -eq $false)
				{
				throw "Not connected to $($radio.model): $($radio.serial). Use connect-flexradio or get-flexradio | connect-flexradio to establish a new connection."
				}

			if (-not ($indexObj = $radio | findFlexRadioIndexNumber))
				{
				throw "Lost source radio object, try running get-flexradio again."
				}

			if ($PSBoundParameters.ContainsKey('AccOn') -and ($ACCOn -ne $radio.AccOn))
				{
				$global:FlexRadios[$indexObj.index].set_AccOn($AccOn)
				}
			}
		}

	end { }
	}


# profile functions need to be rewritten - flex added support for saved profiles since this was written
<#
function get-FlexProfileOLD
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0)]
		[string]$name
		)

	begin { }

	process 
		{
		#foreach ($radio in $RadioObject)
		#	{
		#	if ($radio -eq $null)
		#		{
		#		continue
		#		}


			$PSDir = $profile | split-path
			$ModuleDir = $PSDir + "\FlexModule"
			$ProfileDir = $ModuleDir + "\FlexProfile"

			if (-not (test-path $ProfileDir))
				{
				write-verbose "Path not found: $ProfileDir"
				
				continue
				}

			write-verbose "Looking for saved profiles ..."

			$profiles = get-childitem ($ProfileDir + "\*.radio") -erroraction silentlycontinue

			$flexprofiles = @()

			if ($profiles)
				{
				foreach ($file in $profiles)
					{
					$flexprofile = new-object psobject

					$flexprofile | add-member -MemberType NoteProperty -Name "Profile" -Value ($file.name.split(".")[0])
					$flexprofile | add-member -MemberType NoteProperty -Name "Modified" -Value $file.LastWriteTime

					$flexprofiles += $flexprofile
					}
				}

			$flexprofiles
		#	}
		}

	end { }
	}


function export-FlexProfileOLD
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=1, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject,

		[Parameter(ParameterSetName="p0",Position=0)]
		[string]$name
		)

	begin { }

	process 
		{
		foreach ($radio in $RadioObject)
			{
			if ($radio -eq $null)
				{
				continue
				}

			if (-not ($indexObj = $radio | findFlexRadioIndexNumber))
				{
				throw "Lost source radio object, try running get-flexradio again."
				}

			$PSDir = $profile | split-path

			if (-not (test-path $PSDir))
				{
				write-verbose "Path not found. Creating: $PSDir"

				[void](mkdir $PSDir)
				}

			$ModuleDir = $PSDir + "\FlexModule"

			if (-not (test-path $moduleDir))
				{
				write-verbose "Path not found. Creating: $moduleDir"
				
				[void](mkdir $moduleDir)
				}

			$ProfileDir = $ModuleDir + "\FlexProfile"

			if (-not (test-path $ProfileDir))
				{
				write-verbose "Path not found. Creating: $ProfileDir"
				
				[void](mkdir $ProfileDir)
				}

			# refresh slices/panadapters
			# [void](get-FlexRadioSliceReceiver)	// get-FlexRadioPanadapter calls this for us
			[void](get-FlexRadioPanadapter)

			if (-not ($indexObj = $radio | findFlexRadioIndexNumber))
				{
				throw "Lost source radio object, try running get-flexradio again."
				}

			write-verbose "Exporting radio configuration ..."

			$radioFile = $ProfileDir + "\$name.radio"
			$global:flexradios[$indexObj.index] | export-clixml -depth 4 -path $radioFile

			
			#write-verbose "Exporting slice/panadapter configuration ..."

			#$sliceFile = $ProfileDir + "\$name.slice"
			#$global:slicereceivers | export-clixml -depth 4 -path $sliceFile
			
			}
		}

	end { }
	}
#>

function set-FlexRadio
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial,

		[Parameter(ParameterSetName="p0")]
		[bool]$ACCOn,

		[Parameter(ParameterSetName="p0")]
		[int]$AMCarrierLevel,

		[Parameter(ParameterSetName="p0")]
		[int]$APFGain,

		[Parameter(ParameterSetName="p0")]
		[bool]$APFMode,

		[Parameter(ParameterSetName="p0")]
		[int]$APFQFactor,

		[Parameter(ParameterSetName="p0")]
		[string]$Callsign,

		[Parameter(ParameterSetName="p0")]
		[int]$CompanderLevel,

		[Parameter(ParameterSetName="p0")]
		[bool]$CompanderOn,

		[Parameter(ParameterSetName="p0")]
		[bool]$CWBreakIn,

		[Parameter(ParameterSetName="p0")]
		[int]$CWDelay,

		[Parameter(ParameterSetName="p0")]
		[bool]$CWIambic,

		[Parameter(ParameterSetName="p0")]
		[bool]$CWIambicModeA,

		[Parameter(ParameterSetName="p0")]
		[bool]$CWIambicModeB,

		[Parameter(ParameterSetName="p0")]
		[int]$CWPitch,

		[Parameter(ParameterSetName="p0")]
		[int]$CWSpeed,

		[Parameter(ParameterSetName="p0")]
		[bool]$CWSwapPaddles,

		[Parameter(ParameterSetName="p0")]
		[int]$DelayTX,

		[Parameter(ParameterSetName="p0")]
		[string]$DAXOn,

		[Parameter(ParameterSetName="p0")]
		[int]$HeadphoneGain,

		[Parameter(ParameterSetName="p0")]
		[bool]$HeadphoneMute,

		[Parameter(ParameterSetName="p0")]
		[bool]$HWAlcEnabled,

		[Parameter(ParameterSetName="p0")]
		[int]$LineoutGain,

		[Parameter(ParameterSetName="p0")]
		[bool]$LineoutMute,

		[Parameter(ParameterSetName="p0")]
		[bool]$MetInRX,

		[Parameter(ParameterSetName="p0")]
		[bool]$MicBias,

		[Parameter(ParameterSetName="p0")]
		[bool]$MicBoost,

		[Parameter(ParameterSetName="p0")]
		[int]$MicLevel,

		[Parameter(ParameterSetName="p0")]
		[bool]$Mox,

		[Parameter(ParameterSetName="p0")]
		[string]$Nickname,

		[Parameter(ParameterSetName="p0")]
		[bool]$RemoteOnEnabled,

		[Parameter(ParameterSetName="p0")]
		[int]$RFPower,

		[Parameter(ParameterSetName="p0")]
		[string]$Screensaver,

		[Parameter(ParameterSetName="p0")]
		[bool]$ShowTxInWaterfall,

		[Parameter(ParameterSetName="p0")]
		[bool]$SnapTune,

		[Parameter(ParameterSetName="p0")]
		[bool]$TNFEnabled,

		[Parameter(ParameterSetName="p0")]
		[int]$TunePower,

		[Parameter(ParameterSetName="p0")]
		[bool]$TXReqACCEnabled,

		[Parameter(ParameterSetName="p0")]
		[bool]$TXReqACCPolarity,

		[Parameter(ParameterSetName="p0")]
		[bool]$TXReqRCAEnabled,

		[Parameter(ParameterSetName="p0")]
		[bool]$TXReqRCAPolarity

		)

	begin { }

	process 
		{
		if (-not $Serial)
			{
			if ($global:FlexRadios.count -eq 1)
				{
				write-verbose "One FlexRadio found. Using it."
				$serial = $global:FlexRadios[0].serial
				}
			else
				{
			    throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
				}
			}

		foreach ($radio in $Serial)
			{
			$radioObj = $global:FlexRadios | ? { $_.serial -eq $Serial }

			write-verbose "Serial: $($radioObj.serial)"

			if (-not $radioObj.serial)
				{
				continue
				}
			
			write-verbose "Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false)
				{
				throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
				}

			if ($PSBoundParameters.ContainsKey('AccOn') -and ($ACCOn -ne $radioObj.AccOn))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify AccOn"))
					{
					$radioObj.set_AccOn($AccOn)
					}
				}

			if ($PSBoundParameters.ContainsKey('AMCarrierLevel') -and ($AMCarrierLevel -ne $radioObj.AMCarrierLevel))
				{
				if ($AMCarrierLevel -lt 0) { $AMCarrierLevel = 0 }
				if ($AMCarrierLevel -gt 100) { $AMCarrierLevel = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify AMCarrierLevel"))
					{
					$radioObj.set_AMCarrierLevel($AMCarrierLevel)
					}
				}

			if ($PSBoundParameters.ContainsKey('APFGain') -and ($APFGain -ne $radioObj.APFGain))
				{
				if ($APFGain -lt 0) { $APFGain = 0 }
				if ($APFGain -gt 100) { $APFGain = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify APFGain"))
					{
					$radioObj.set_APFGain($APFGain)
					}
				}

			if ($PSBoundParameters.ContainsKey('APFMode') -and ($APFMode -ne $radioObj.APFMode))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify APFMode"))
					{
					$radioObj.set_APFMode($APFMode)
					}
				}

			if ($PSBoundParameters.ContainsKey('APFQFactor') -and ($APFQFactor -ne $radioObj.APFQFactor))
				{
				if ($APFQFactor -lt 0) { $APFQFactor = 0 }
				if ($APFQFactor -gt 33) { $APFQFactor = 33 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify APFQFactor"))
					{
					$radioObj.set_APFQFactor($APFQFactor)
					}
				}

			if ($PSBoundParameters.ContainsKey('Callsign') -and ($Callsign -ne $radioObj.Callsign))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Callsign"))
					{
					$radioObj.set_Callsign($Callsign)
					}
				}

			if ($PSBoundParameters.ContainsKey('CompanderLevel') -and ($CompanderLevel -ne $radioObj.CompanderLevel))
				{
				if ($CompanderLevel -lt 0) { $CompanderLevel = 0 }
				if ($CompanderLevel -gt 100) { $CompanderLevel = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CompanderLevel"))
					{
					$radioObj.set_CompanderLevel($CompanderLevel)
					}
				}

			if ($PSBoundParameters.ContainsKey('CompanderOn') -and ($CompanderOn -ne $radioObj.CompanderOn))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CompanderOn"))
					{
					$radioObj.set_CompanderOn($CompanderOn)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWBreakIn') -and ($CWBreakIn -ne $radioObj.CWBreakIn))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWBreakIn"))
					{
					$radioObj.set_CWBreakIn($CWBreakIn)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWDelay') -and ($CWDelay -ne $radioObj.CWDelay))
				{
				if ($CWDelay -lt 0) { $CWDelay = 0 }
				if ($CWDelay -gt 2000) { $CWDelay = 2000 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWDelay"))
					{
					$radioObj.set_CWDelay($CWDelay)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWIambic') -and ($CWIambic -ne $radioObj.CWIambic))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWIambic"))
					{
					$radioObj.set_CWIambic($CWIambic)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWIambicModeA') -and ($CWIambicModeA -ne $radioObj.CWIambicModeA))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWIambicModeA"))
					{
					$radioObj.set_CWIambicModeA($CWIambicModeA)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWIambicModeB') -and ($CWIambicModeB -ne $radioObj.CWIambicModeB))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWIambicModeB"))
					{
					$radioObj.set_CWIambicModeB($CWIambicModeB)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWPitch') -and ($CWPitch -ne $radioObj.CWPitch))
				{
				if ($CWPitch -lt 100) { $CWPitch = 100 }
				if ($CWPitch -gt 6000) { $CWPitch = 6000 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWPitch"))
					{
					$radioObj.set_CWPitch($CWPitch)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWSpeed') -and ($CWSpeed -ne $radioObj.CWSpeed))
				{
				if ($CWSpeed -lt 5) { $CWSpeed = 5 }
				if ($CWSpeed -gt 100) { $CWSpeed = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWSpeed"))
					{
					$radioObj.set_CWSpeed($CWSpeed)
					}
				}

			if ($PSBoundParameters.ContainsKey('CWSwapPaddles') -and ($CWSwapPaddles -ne $radioObj.CWSwapPaddles))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CWSwapPaddles"))
					{
					$radioObj.set_CWSwapPaddles($CWSwapPaddles)
					}
				}

			if ($PSBoundParameters.ContainsKey('DelayTX') -and ($DelayTX -ne $radioObj.DelayTX))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify DelayTX"))
					{
					$radioObj.set_DelayTX($DelayTX)
					}
				}

			if ($PSBoundParameters.ContainsKey('DAXOn') -and ($DAXOn -ne $radioObj.DAXOn))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify DAXOn"))
					{
					$radioObj.set_DAXOn($DAXOn)
					}
				}

			if ($PSBoundParameters.ContainsKey('HeadphoneGain') -and ($HeadphoneGain -ne $radioObj.HeadphoneGain))
				{
				if ($HeadphoneGain -lt 0) { $HeadphoneGain = 0 }
				if ($HeadphoneGain -gt 100) { $HeadphoneGain = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify HeadphoneGain"))
					{
					$radioObj.set_HeadphoneGain($HeadphoneGain)
					}
				}

			if ($PSBoundParameters.ContainsKey('HeadphoneMute') -and ($HeadphoneMute -ne $radioObj.HeadphoneMute))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify HeadphoneMute"))
					{
					$radioObj.set_HeadphoneMute($HeadphoneMute)
					}
				}

			if ($PSBoundParameters.ContainsKey('HWAlcEnabled') -and ($HWAlcEnabled -ne $radioObj.HWAlcEnabled))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify HWAlcEnabled"))
					{
					$radioObj.set_HWAlcEnabled($HWAlcEnabled)
					}
				}

			if ($PSBoundParameters.ContainsKey('LineoutGain') -and ($LineoutGain -ne $radioObj.LineoutGain))
				{
				if ($LineoutGain -lt 0) { $LineoutGain = 0 }
				if ($LineoutGain -gt 100) { $LineoutGain = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify LineoutGain"))
					{
					$radioObj.set_LineoutGain($LineoutGain)
					}
				}

			if ($PSBoundParameters.ContainsKey('LineoutMute') -and ($LineoutMute -ne $radioObj.LineoutMute))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify LineoutMute"))
					{
					$radioObj.set_LineoutMute($LineoutMute)
					}
				}

			if ($PSBoundParameters.ContainsKey('MetInRX') -and ($MetInRX -ne $radioObj.MetInRX))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify MetInRX"))
					{
					$radioObj.set_MetInRX($MetInRX)
					}
				}

			if ($PSBoundParameters.ContainsKey('MicBias') -and ($MicBias -ne $radioObj.MicBias))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify MicBias"))
					{
					$radioObj.set_MicBias($MicBias)
					}
				}

			if ($PSBoundParameters.ContainsKey('MicBoost') -and ($MicBoost -ne $radioObj.MicBoost))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify MicBoost"))
					{
					$radioObj.set_MicBoost($MicBoost)
					}
				}

			if ($PSBoundParameters.ContainsKey('MicLevel') -and ($MicLevel -ne $radioObj.MicLevel))
				{
				if ($MicLevel -lt 0) { $MicLevel = 0 }
				if ($MicLevel -gt 100) { $MicLevel = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify MicLevel"))
					{
					$radioObj.set_MicLevel($MicLevel)
					}
				}

			if ($PSBoundParameters.ContainsKey('Mox') -and ($Mox -ne $radioObj.Mox))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Mox"))
					{
					$radioObj.set_Mox($Mox)
					}
				}

			if ($PSBoundParameters.ContainsKey('Nickname') -and ($Nickname -ne $radioObj.Nickname))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Nickname"))
					{
					$radioObj.set_Nickname($Nickname)
					}
				}

			if ($PSBoundParameters.ContainsKey('RemoteOnEnabled') -and ($RemoteOnEnabled -ne $radioObj.RemoteOnEnabled))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RemoteOnEnabled"))
					{
					$radioObj.set_RemoteOnEnabled($RemoteOnEnabled)
					}
				}

			if ($PSBoundParameters.ContainsKey('RFPower') -and ($RFPower -ne $radioObj.RFPower))
				{
				if ($RFPower -lt 0) { $RFPower = 0 }
				if ($RFPower -gt 100) { $RFPower = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RFPower"))
					{
					$radioObj.set_RFPower($RFPower)
					}
				}

			if ($PSBoundParameters.ContainsKey('Screensaver') -and ($Screensaver -ne $radioObj.Screensaver))
				{
				if (($Screensaver -ne "name") -and ($Screensaver -ne "callsign"))
					{
					throw "Valid options for Screensaver are 'name' and 'callsign'."
					}

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Screensaver"))
					{
					$radioObj.set_Screensaver($Screensaver)
					}
				}

			if ($PSBoundParameters.ContainsKey('ShowTxInWaterfall') -and ($ShowTxInWaterfall -ne $radioObj.ShowTxInWaterfall))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify ShowTxInWaterfall"))
					{
					$radioObj.set_ShowTxInWaterfall($ShowTxInWaterfall)
					}
				}

			if ($PSBoundParameters.ContainsKey('SnapTune') -and ($SnapTune -ne $radioObj.SnapTune))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify SnapTune"))
					{
					$radioObj.set_SnapTune($SnapTune)
					}
				}


			if ($PSBoundParameters.ContainsKey('TNFEnabled') -and ($TNFEnabled -ne $radioObj.TNFEnabled))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify TNFEnabled"))
					{
					$radioObj.set_TNFEnabled($TNFEnabled)
					}
				}

			if ($PSBoundParameters.ContainsKey('TunePower') -and ($TunePower -ne $radioObj.TunePower))
				{
				if ($TunePower -lt 0) { $TunePower = 0 }
				if ($TunePower -gt 100) { $TunePower = 100 }

				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify TunePower"))
					{
					$radioObj.set_TunePower($TunePower)
					}
				}

			if ($PSBoundParameters.ContainsKey('TXReqACCEnabled') -and ($TXReqACCEnabled -ne $radioObj.TXReqACCEnabled))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify TXReqACCEnabled"))
					{
					$radioObj.set_TXReqACCEnabled($TXReqACCEnabled)
					}
				}

			if ($PSBoundParameters.ContainsKey('TXReqACCPolarity') -and ($TXReqACCPolarity -ne $radioObj.TXReqACCPolarity))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify TXReqACCPolarity"))
					{
					$radioObj.set_TXReqACCPolarity($TXReqACCPolarity)
					}
				}

			if ($PSBoundParameters.ContainsKey('TXReqRCAEnabled') -and ($TXReqRCAEnabled -ne $radioObj.TXReqRCAEnabled))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify TXReqRCAEnabled"))
					{
					$radioObj.set_TXReqRCAEnabled($TXReqRCAEnabled)
					}
				}

			if ($PSBoundParameters.ContainsKey('TXReqRCAPolarity') -and ($TXReqRCAPolarity -ne $radioObj.TXReqRCAPolarity))
				{
				if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify TXReqRCAPolarity"))
					{
					$radioObj.set_TXReqRCAPolarity($TXReqRCAPolarity)
					}
				}
			}
		}

	end { }
	}

function get-FlexProfile
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
		[string]$Serial
		)

	begin { }

	process 
		{
		if (-not $Serial)
			{
			if ($global:FlexRadios.count -eq 1)
				{
				write-verbose "One FlexRadio found. Using it."
				$Serial = $global:FlexRadios[0].serial
				}
			else
				{
			    throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
				}
			}

		foreach ($radio in $Serial)
			{
			$radioObj = $global:FlexRadios | ? { $_.serial -eq $Serial }

			write-verbose "Serial: $($radioObj.serial)"

			if (-not $radioObj.serial)
				{
				continue
				}
			
			write-verbose "Radio connected: $($radioObj.connected)"

			if ($radioObj.Connected -eq $false)
				{
				write-warning "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."

				continue
				}

			# start building the profile object

			# ProfileMicList
			foreach ($profile in $radioObj.ProfileMicList)
				{
				if ($profile -eq $null)
					{
					continue
					}

				$profileObj = new-object psobject

				$profileObj | add-member NoteProperty -Name "ProfileType" -Value "Mic"
				$profileObj | add-member NoteProperty -Name "Name" -Value $profile

				if ($profile -eq $radioObj.profileMicSelection)
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $true
					}
				else
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $false
					}

				$profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
				$profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
				$profileObj
				}

			# ProfileTXList
			foreach ($profile in $radioObj.ProfileTXList)
				{
				if ($profile -eq $null)
					{
					continue
					}

				$profileObj = new-object psobject

				$profileObj | add-member NoteProperty -Name "ProfileType" -Value "TX"
				$profileObj | add-member NoteProperty -Name "Name" -Value $profile

				if ($profile -eq $radioObj.profileTXSelection)
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $true
					}
				else
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $false
					}

				$profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
				$profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
				$profileObj
				}

			# ProfileDisplayList
			foreach ($profile in $radioObj.ProfileDisplayList)
				{
				if ($profile -eq $null)
					{
					continue
					}

				$profileObj = new-object psobject

				$profileObj | add-member NoteProperty -Name "ProfileType" -Value "Display"
				$profileObj | add-member NoteProperty -Name "Name" -Value $profile

				if ($profile -eq $radioObj.profileDisplaySelection)
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $true
					}
				else
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $false
					}

				$profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
				$profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
				$profileObj
				}

			# ProfileGlobalList
			foreach ($profile in $radioObj.ProfileGlobalList)
				{
				if ($profile -eq $null)
					{
					continue
					}

				$profileObj = new-object psobject

				$profileObj | add-member NoteProperty -Name "ProfileType" -Value "Global"
				$profileObj | add-member NoteProperty -Name "Name" -Value $profile

				if ($profile -eq $radioObj.profileGlobalSelection)
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $true
					}
				else
					{
					$profileObj | add-member NoteProperty -Name "Selected" -Value $false
					}

				$profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
				$profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
				$profileObj
				}
			
			}
		}

	end { }
	}



export-modulemember -function get-FlexRadio
export-modulemember -function set-FlexRadio
export-modulemember -function set-FlexSliceReceiver
export-modulemember -function set-FlexPanadapter
export-modulemember -function connect-flexradio
export-modulemember -function disconnect-flexradio
export-modulemember -function get-FlexSliceReceiver
export-modulemember -function get-FlexPanadapter
export-modulemember -function get-flexpacket
export-modulemember -function get-packet
export-modulemember -function get-flexlatestfolderpath
export-modulemember -function get-FlexProfile
export-modulemember -function *-FlexMemory
export-modulemember -function export-FlexDatabase
