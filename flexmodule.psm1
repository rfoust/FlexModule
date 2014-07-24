
. $PSScriptRoot\get-packet.ps1

function get-flexlatestfolderpath
	{
	$flexRoot = "c:\program files\FlexRadio Systems"

	if (test-path $flexRoot)
		{
		$dirs = gci $flexRoot

		if (-not $dirs)
			{
			throw "Unable to locate FlexRadio SmartSDR installation path!"
			}

		$modifiedDirs = @()

		foreach ($dir in $dirs)
			{
			$rootName,$fullVersion,$null = $dir.name -split " "

			if ($fullVersion)
				{
				$flexVersion = [version]($fullVersion -replace "v","")

				$modifiedDir = $dir | add-member NoteProperty Version $flexVersion -passthru

				$modifiedDirs += $modifiedDir
				}
			}

		if ($modifiedDirs)
			{
			($modifiedDirs | sort Version -desc)[0].fullname
			}
		}
	}

function get-flexlibpath
	{
	$latestPath = get-flexlatestfolderpath

	if ($latestPath)
		{
		$latestpath + "\FlexLib.dll"
		}
	}

function import-flexlib
	{
	$flexLibPath = get-flexlibpath

	if ($flexLibPath)
		{
		try
			{
			[void][reflection.assembly]::GetAssembly([flex.smoothlake.FlexLib.api])
			}
		catch [system.exception]
			{
			add-type -path $flexLibPath
			}
		}
	else
		{
	    throw "Unable to locate FlexRadio FlexLib library!"
		}

	[flex.smoothlake.FlexLib.api]::init()
	}

import-flexlib

function displayTime
	{
	$now = get-date -format "HH:mm:ss"

	write-host "[" -foregroundcolor green -nonewline
	write-host $now -foregroundcolor gray -nonewline
	write-host "]" -foregroundcolor green -nonewline
	# write-host " : " -foregroundcolor white -nonewline
	}

function displaySource ([string]$source, [int]$pad = 15)
	{

	$source = $source.padleft($pad)

	switch -wildcard ($source)
		{
		"*Radio"
			{
			$foreColor = "magenta"
			break
			}
		"*Local"
			{
			$foreColor = "cyan"
			break
			}
		"*RadioResponse"
			{
			$foreColor = "yellow"
			break
			}
		"*RadioStatus"
			{
			$foreColor = "blue"
			break
			}
		"*RadioMessage"
			{
			$foreColor = "green"
			break
			}
		"`*"
			{
			$foreColor = "cyan"
			break
			}
		default
			{
			$foreColor = "gray"
			break
			}
		}
	
	write-host $source -foregroundcolor $foreColor -nonewline
	write-host " : " -foregroundcolor  white -nonewline
	}

function displayData ([string]$data)
	{
	$consoleWidth = $host.ui.rawui.windowsize.width
	$leftPad = 28	# 10 for date/time, 15 for source + padding + extra stuff
	#$dataLength = $data.length 
	$maxDataWidth = $consoleWidth - $leftPad - 2	# the 3 is for the " : " in the prefix string, and subtract one for a right pad

	$firstLine = $true
	$dataStringIndex = 0		#starting point
	$processing = $true

	while ($processing)
		{
		if ($firstLine)
			{
			if (($maxDataWidth -ge $data.length) -or ($dataStringIndex -gt $data.length))
				{
				$outputString = $data
				$processing = $false
				}
			else
				{
				$outputString = $data.substring($dataStringIndex,$maxDataWidth)
				$dataStringIndex = $dataStringIndex + $maxDataWidth
				}
			}
		else
			{
			if (($maxDataWidth -ge ($data.length - ($dataStringIndex + 1))) -or ($dataStringIndex -gt $data.length))
				{
				$outputString = $data.substring($dataStringIndex,$data.length - ($dataStringIndex))
				$processing = $false
				}
			else
				{
				$outputString = $data.substring($dataStringIndex,$maxDataWidth)
				$dataStringIndex = $dataStringIndex + $maxDataWidth
				}
			}

		if ($firstLine)
			{
			write-host $outputString -foregroundcolor gray
			$firstLine = $false
			}
		else
			{
			write-host (" : ").padleft($leftPad) -foregroundcolor white -nonewline
			write-host $outputString -foregroundcolor gray
			}
		}
	}

function get-flexpacket
	{
	$smartSDRdetected = $false
	$SmartSDRVersion = (get-process | ? { $_.processname -match "SmartSDR" }).productversion

	if ($SmartSDRVersion)
		{
		displayTime
		displaySource "*"
		write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
		$smartSDRdetected = $true
		}

	$remoteIP = (get-flexradio).ip

	if (-not $remoteIP)
		{
		throw "Unable to locate FlexRadio IP address!"
		}

	$fragment = $null
	$fragmentFound = $false

	#get-packet | ? { ($_.source -eq "192.168.1.133" -or $_.destination -eq "192.168.1.133") -and ($_.protocol -eq "TCP")} | % {
	get-packet -protocol flex -remoteIP $remoteIP | % {
		$packet = $_

		if ((-not $packet) -or ($packet.length -le 0))
			{
			continue
			}

		if ($smartSDRdetected -eq $false)
			{
			$SmartSDRVersion = (get-process | ? { $_.processname -match "SmartSDR" }).productversion

			if ($SmartSDRVersion)
				{
				displayTime
				displaySource "*"
				write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
				$smartSDRdetected = $true
				}
			}

		if ($fragmentFound)
			{
			$newData = ($packet -split '\n')[0]
			$newDataComplete = $fragment + $newData

			$packet = $packet -replace [regex]::Escape($newData),$newDataComplete

			$fragmentFound = $false
			}

		if ($packet -notmatch '\Z\n')
			{
			$fragment = "`n" + ($packet -split '\n')[-1]

			if ($fragment -ne "`n")
				{
				$packet = $packet -replace [regex]::Escape($fragment),''

				$fragmentFound = $true
				}
			}

		$packet -split '\n' | % { $_ -replace '^\x00*','' } | ? { $_ -ne "" -and $_ -ne $null } | % {

			$packetdata = $_

			$prefix = $packetdata[0]

			if ($packetdata)
				{
				[string]$packetSubData = $packetdata.substring(1)
				}

			switch ($prefix)
				{
				"V"
					{
					displayTime
					displaySource "Radio"
					write-host "Version $($packetSubData)" -foregroundcolor green
					break
					}
				"H"
					{
					displayTime
					displaySource "Radio"
					write-host "Handle received: $($packetSubData)" -foreground green
					break
					}
				"C"	# command sent
					{
					displayTime
					displaySource "Local"
					$sequence,$command = $packetSubData.split("|")
					displayData "#$sequence - $command"
					break
					}
				"R"
					{
					displayTime
					displaySource "RadioResponse"
					$sequence,$command = $packetSubData.split("|")
					displayData "#$sequence - $command"
					break
					}
				"S"
					{
					displayTime
					displaySource "RadioStatus"
					$handle,$command = $packetSubData.split("|")
					displayData "($handle) - $command"
					break
					}
				"M"
					{
					displayTime
					displaySource "RadioMessage"
					$handle,$command = $packetSubData.split("|")

					#switch ($handle)
					#	{
					#	# decode message number for severity
					#	}
					write-host "$command"
					break
					}
				default
					{
					displayTime
					displaySource "Fragment"
					displayData "$packetData"
					}
				}
			}
		}
	}

# note: serial number (property name "serial") should be the primary identifier for each radio
# there is a global variable $global:flexradios that will contain all flex radios found
# the various module cmdlets should be able to get/set on that object by finding a matching serial number.

function get-flexradio
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
		[string]$SerialNumber,

		[Parameter(ParameterSetName="p0",Position=1)]
		[switch]$Discover
		)

	begin { }

	process 
		{
		$count = 0
		$found = $false
		$AllRadios = @()

		while (($count -le 10) -and !$found)
			{
			# try to discover FlexRadios on the network
			if ($discover -or (-not $global:flexradios))
				{
				$global:FlexRadios = [flex.smoothlake.flexlib.api]::RadioList
				}

			if (-not $global:flexradios)
				{
				write-verbose "No FlexRadios found, searching ($count of 10) ..."

				start-sleep -milliseconds 250
				$count++
				}
			else
				{
				$found = $true
				}
			}

		if ($SerialNumber)
			{
			$global:FlexRadios | ? { $_.serial -eq $SerialNumber }
			}
		else
			{
		    $global:FlexRadios
			}
		}

	end { }
	}


function findFlexRadioIndexNumber
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject
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

			for ($loop = 0; $loop -le ($global:flexradios.count - 1); $loop++)
				{
				if ($global:flexradios[$loop].serial -eq $radio.serial)
					{
					$radioObj = new-object psobject

					$radioObj | add-member -MemberType NoteProperty -Name "Serial" -Value $radio.serial
					$radioObj | add-member -MemberType NoteProperty -Name "Index" -Value $loop

					$radioObj
					}
				}
			}
		}

	end { }
	}


function connect-flexradio
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject
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

			$result = $global:flexradios[$indexObj.index].connect()

			if ($result -eq $false)
				{
				throw "Connect() result was False, unable to connect to radio."
				}
			else
				{
				$count = 0

				while ($count -lt 5)
					{
					if ($global:flexradios[$indexObj.index].Connected -eq $true)
						{
						$global:flexradios[$indexObj.index]

						break
						}

					$count++
					}
				}
			}
		}

	end { }
	}

function disconnect-flexradio
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject
		)

	begin { }

	process 
		{
		foreach ($radio in $RadioObject)
			{
			if (($radio -eq $null) -or ($radio -eq ""))
				{
				continue
				}

			if (-not ($indexObj = $radio | findFlexRadioIndexNumber))
				{
				throw "Lost source radio object, try running get-flexradio again."
				}

			$global:flexradios[$indexObj.index].disconnect()

			while ($count -lt 5)
				{
				if ($global:flexradios[$indexObj.index].Connected -eq $false)
					{
					$global:flexradios[$indexObj.index]

					break
					}

				$count++
				}

			}
		}

	end { }
	}

	
function get-flexsetting
	{
	$radio | gm | ? { $_.membertype -eq "Property" }
	}

function get-FlexSliceReceiver
	{
	[CmdletBinding(DefaultParameterSetName="p0",
		SupportsShouldProcess=$true,
		ConfirmImpact="Low")]
	param(
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject
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

			$global:slicereceivers = @()

			for ($SliceIndex = 0; $SliceIndex -le 8; $SliceIndex++)
				{
				write-verbose "Searching index $SliceIndex"

				$global:slicereceivers += $global:flexradios[$indexObj.index].FindSliceByIndex($SliceIndex)
				}

			$global:slicereceivers
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
		[Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
		[ValidateScript({$_.serial})]  # must have serial number
		$RadioObject
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

			# refresh slice receiver list
			[void](get-FlexSliceReceiver)

			$global:panadapters = @()

			$streamIDs = @()

			foreach ($slice in $global:slicereceivers)
				{
				if ($slice -eq $null)
					{
					continue
					}

				if ($streamIDs -notcontains $slice.PanadapterStreamID)
					{
					$global:panadapters += $slice.panadapter

					$streamIDs += $slice.PanadapterStreamID
					}
				}

			$global:panadapters
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


function export-FlexProfile
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

			<#
			write-verbose "Exporting slice/panadapter configuration ..."

			$sliceFile = $ProfileDir + "\$name.slice"
			$global:slicereceivers | export-clixml -depth 4 -path $sliceFile
			#>
			}
		}

	end { }
	}

function set-FlexRadio
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


export-modulemember -function get-FlexRadio
export-modulemember -function set-FlexRadio
export-modulemember -function connect-flexradio
export-modulemember -function disconnect-flexradio
export-modulemember -function get-FlexSliceReceiver
export-modulemember -function get-FlexPanadapter
export-modulemember -function get-flexpacket
export-modulemember -function get-packet
