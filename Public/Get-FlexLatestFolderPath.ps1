function Get-FlexLatestFolderPath {
	$flexRoot = "c:\program files\FlexRadio Systems"

	if (test-path $flexRoot) {
		$dirs = Get-ChildItem $flexRoot

		if (-not $dirs) {
			throw "Unable to locate FlexRadio SmartSDR installation path!"
		}

		$modifiedDirs = @()

		foreach ($dir in $dirs) {
			$rootName, $fullVersion, $null = $dir.name -split " "

			if ($fullVersion) {
				$beta = $false

				if ($fullVersion -match "Beta") {
					$beta = $true

					$fullVersion = $fullVersion -replace "Beta_", ""
				}

				$flexVersion = [version]($fullVersion -replace "v", "")

				$modifiedDir = $dir | add-member NoteProperty Version $flexVersion -passthru
				$modifiedDir = $modifiedDir | add-member NoteProperty Beta $beta -passthru

				$modifiedDirs += $modifiedDir
			}
		}

		if ($modifiedDirs) {
			$latest = $null
			$latest = ($modifiedDirs | Sort-Object Version -desc)[0]

			if ($latest.beta) {
				write-warning "FYI - Latest version of SmartSDR installed is a Beta version (v$($latest.Version))."
			}

			$latest.fullname
		}
	}
}
