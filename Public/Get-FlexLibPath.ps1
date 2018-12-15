function Get-FlexLibPath {
	[CmdletBinding(DefaultParameterSetName = "p0",
		SupportsShouldProcess = $false,
		ConfirmImpact = "Low")]
	param()

	begin { }

	process {
		$flexDLL = $null
		$DLLdata = $null

		$latestPath = get-flexlatestfolderpath

		if ($latestPath) {
			$flexDLL = $latestpath + "\FlexLib.dll"

			write-verbose "Using: $flexDLL"

			if (test-path $flexDLL) {
				$DLLdata = [reflection.assemblyname]::getassemblyname($flexDLL)

				write-verbose "ProcessorArchitecture: $($DLLdata.ProcessorArchitecture)"

				if (($DLLdata.ProcessorArchitecture -ne "MSIL") -and (test-win64)) { # x86 dll on 64 bit host?
					write-verbose "Incompatible FlexLib - Wrong architecture!"

					$moduleRoot = split-path (get-module -ListAvailable flexmodule).path

					if (test-path ($moduleRoot + "\Lib\FlexLib.dll")) {
						# this is our last hope to find a compatible flexlib dll
						write-verbose "Using DLL included with FlexModule."

						$moduleRoot + "\Lib\FlexLib.dll"
					}
					else {
						return
					}
				}
				else {
					$flexDLL
				}
			}
		}
	}

	end { }
}
