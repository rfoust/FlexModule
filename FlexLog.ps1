function Get-FlexLog {
	[CmdletBinding(DefaultParameterSetName = "p0")]

	param(
		[Parameter(ParameterSetName = "p0")]
		[switch]$FlexControl,

		[Parameter(ParameterSetName = "p0")]
		[switch]$Discovery,

		[Parameter(ParameterSetName = "p0")]
		[switch]$Disconnect
	)

	begin {
		$FCLog = (join-path $env:AppData "FlexRadio Systems\LogFiles\SSDR_FCManager.log")
		$DiscoveryLog = (Join-Path $env:AppData "FlexRadio Systems\LogFiles\SSDR_Discovery.log")
		$DisconnectLog = (Join-Path $env:AppData "FlexRadio Systems\LogFiles\SSDR_Disconnect.log")

		if (!(Test-Path $FCLog)) {
			write-warning "$FCLog not found!"

			$FCLog = $null
		}
		if (!(Test-Path $DiscoveryLog)) {
			write-warning "$DiscoveryLog not found!"

			$DiscoveryLog = $null
		}
		if (!(Test-Path $DisconnectLog)) {
			write-warning "$DisconnectLog not found!"

			$DisconnectLog = $null
		}

		if (!$FlexControl -and !$Discovery -and !$Disconnect) {
			$All = $true
		}
	}

	process {
		if ($FlexControl -or $All -and $FCLog) {
			$lastDate = $null

			foreach ($line in (get-content $FCLog)) {
				if (!$line) {
					continue
				}

				write-verbose "Raw line: $line"
				write-verbose "Line Length: $($line.length)"

				if ($line -and ($line.length -gt 0) -and ($line -match "^\S")) {
					$line = $line -replace "M: ", "M|"

					write-verbose "Initial split: $line"

					[datetime]$logEntryDate, [string]$logData = $line -split "\|"

					write-verbose "Date: $logEntryDate"
					write-verbose "LogData: $logData"

					# used if the prior line wrapped; wrapped lines won't have a date
					$lastDate = $logEntryDate

					$logEntry = new-object psobject

					$logEntry | add-member NoteProperty "Timestamp" $logEntryDate
					$logEntry | add-member NoteProperty "Data" $logData

					$logEntry
				}
				elseif ($lastDate -and ($line.length -gt 0)) {
					$logEntry = new-object psobject

					$logEntry | add-member NoteProperty "Timestamp" $lastDate
					$logEntry | add-member NoteProperty "Data" $line.trimstart()

					$logEntry
				}
			}
		}

		if ($Discovery -or $All -and $DiscoveryLog) {
			foreach ($line in (Get-Content $DiscoveryLog)) {
				if (!$line) {
					continue
				}

				write-verbose "Raw line: $line"
				write-verbose "Line Length: $($line.length)"

				$logentrydate = $null
				$logentrydate = $line | ForEach-Object { $_ -match "\d{1,2}/\d{1,2}/\d{4}\s+\d{2}:\d{2}:\d{2}" | Out-Null; [datetime]$matches[0] }

				$substring = $line | ForEach-Object { $_ -replace "\d{1,2}/\d{1,2}/\d{4}\s+\d{2}:\d{2}:\d{2}\s", "" }
				$application = ($substring -split ":")[0]

				$logdata = ($substring -split "\d{1,2}/\d{1,2}/\d{4}\s+\d{2}:\d{2}:\d{2}").split(":\s", 2)[-1]

				$logEntry = new-object psobject

				$logEntry | add-member NoteProperty "Timestamp" $logEntryDate
				$logEntry | add-member NoteProperty "Application" $application
				$logEntry | add-member NoteProperty "Data" $logData

				$logEntry
			}
		}

		if ($Disconnect -or $All -and $DisconnectLog) {
			foreach ($line in (Get-Content $DisconnectLog)) {
				if (!$line) {
					continue
				}

				write-verbose "Raw line: $line"
				write-verbose "Line Length: $($line.length)"

				$logentrydate = $null
				$logentrydate = $line | ForEach-Object { $_ -match "\d{1,2}/\d{1,2}/\d{4}\s+\d{2}:\d{2}:\d{2}" | Out-Null; [datetime]$matches[0] }

				$substring = $line | ForEach-Object { $_ -replace "\d{1,2}/\d{1,2}/\d{4}\s+\d{2}:\d{2}:\d{2}\s", "" }
				$application = ($substring -split ":")[0]

				$logdata = ($substring -split "\d{1,2}/\d{1,2}/\d{4}\s+\d{2}:\d{2}:\d{2}").split(":\s", 2)[-1]

				$logEntry = new-object psobject

				$logEntry | add-member NoteProperty "Timestamp" $logEntryDate
				$logEntry | add-member NoteProperty "Application" $application
				$logEntry | add-member NoteProperty "Data" $logData

				$logEntry
			}
		}

	}

	end { }
}

function Enable-FlexLog {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true)]

	param(
		[Parameter(ParameterSetName = "p0")]
		[switch]$Discovery,

		[Parameter(ParameterSetName = "p0")]
		[switch]$Disconnect
	)

	begin {
		if (!$Discovery -and !$Disconnect) {
			$All = $true
		}

		$DiscoveryEnableFile = (Join-Path $env:AppData "FlexRadio Systems\log_discovery.txt")
		$DisconnecEnableFile = (Join-Path $env:AppData "FlexRadio Systems\log_disconnect.txt")

		$LogFolder = (join-path $env:AppData "FlexRadio Systems\LogFiles")

		if (!(Test-Path $LogFolder)) {
			Write-Verbose "Creating folder: $LogFolder"

			mkdir $LogFolder | out-null
		}
	}

	process {
		if ($Discovery -or $All) {
			if (!(Test-Path $DiscoveryEnableFile)) {
				$DiscoveryEnableFile | Out-File $DiscoveryEnableFile -Encoding ascii
			}
		}

		if ($Disconnect -or $All) {
			if (!(Test-Path $DisconnecEnableFile)) {
				$DisconnecEnableFile | Out-File $DisconnecEnableFile -Encoding ascii
			}
		}
	}

	end { }
}

function Disable-FlexLog {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $true)]

	param(
		[Parameter(ParameterSetName = "p0")]
		[switch]$Discovery,

		[Parameter(ParameterSetName = "p0")]
		[switch]$Disconnect
	)

	begin {
		if (!$Discovery -and !$Disconnect) {
			$All = $true
		}

		$DiscoveryEnableFile = (Join-Path $env:AppData "FlexRadio Systems\log_discovery.txt")
		$DisconnecEnableFile = (Join-Path $env:AppData "FlexRadio Systems\log_disconnect.txt")
	}

	process {
		if ($Discovery -or $All) {
			if (Test-Path $DiscoveryEnableFile) {
				Remove-Item $DiscoveryEnableFile
			}
		}

		if ($Disconnect -or $All) {
			if (Test-Path $DisconnecEnableFile) {
				Remove-Item $DisconnecEnableFile
			}
		}

	}

	end { }
}