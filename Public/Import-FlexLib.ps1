function Import-FlexLib {
	$flexLibPath = get-flexlibpath

	if ($flexLibPath) {
		try {
			[void][reflection.assembly]::GetAssembly([flex.smoothlake.FlexLib.api])
		}
		catch [system.exception] {
			push-location (split-path $flexLibPath)
			add-type -path $flexLibPath
			pop-location
		}
	}
	else {
		throw "Unable to locate FlexRadio FlexLib DLL, or DLL is incompatible with this architecture!"
	}

	# [flex.smoothlake.FlexLib.api]::init()
}
