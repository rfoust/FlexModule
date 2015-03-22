
. $PSScriptRoot\get-packet.ps1
. $PSScriptRoot\FlexRadio.ps1
. $PSScriptRoot\FlexPacket.ps1
. $PSScriptRoot\FlexLib.ps1
. $PSScriptRoot\FlexBackup.ps1
. $PSScriptRoot\FlexMemory.ps1
. $PSScriptRoot\FlexProfile.ps1
. $PSScriptRoot\FlexSlice.ps1
. $PSScriptRoot\FlexPanadapter.ps1

# todo: send "exit reboot" to reboot radio.

import-flexlib


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
