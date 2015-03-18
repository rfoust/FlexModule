# FlexLib.ps1

# Is this a Wow64 powershell host
function Test-Wow64() {
    return (Test-Win32) -and (test-path env:\PROCESSOR_ARCHITEW6432)
}

# Is this a 64 bit process
function Test-Win64() {
    return [IntPtr]::size -eq 8
}

# Is this a 32 bit process
function Test-Win32() {
    return [IntPtr]::size -eq 4
}

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
    $flexDLL = $null
    $DLLdata = $null

    $latestPath = get-flexlatestfolderpath

    if ($latestPath)
        {
        $flexDLL = $latestpath + "\FlexLib.dll"

        if (test-path $flexDLL)
            {
            $DLLdata = [reflection.assemblyname]::getassemblyname($flexDLL)

            if (($DLLdata.ProcessorArchitecture -ne "MSIL") -and (test-win64))  # x86 dll on 64 bit host?
                {
                write-verbose "Incompatible FlexLib - Wrong architecture!"

                $moduleRoot = split-path (get-module -ListAvailable flexmodule).path

                if (test-path ($moduleRoot + "\FlexLib.dll"))
                    {
                    # this is our last hope to find a compatible flexlib dll
                    write-verbose "Using DLL included with FlexModule."

                    $moduleRoot + "\FlexLib.dll"
                    }
                else
                    {
                    return
                    }
                }
            else
                {
                $flexDLL
                }
            }
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
        throw "Unable to locate FlexRadio FlexLib DLL, or DLL is incompatible with this architecture!"
        }

    [flex.smoothlake.FlexLib.api]::init()
    }
