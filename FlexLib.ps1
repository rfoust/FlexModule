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

function Get-FlexLatestFolderPath
    {
    $flexRoot = "c:\program files\FlexRadio Systems"

    if (test-path $flexRoot)
        {
        $dirs = Get-ChildItem $flexRoot

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
                $beta = $false

                if ($fullVersion -match "Beta")
                  {
                  $beta = $true

                  $fullVersion = $fullVersion -replace "Beta_",""
                  }

                $flexVersion = [version]($fullVersion -replace "v","")

                $modifiedDir = $dir | add-member NoteProperty Version $flexVersion -passthru
                $modifiedDir = $modifiedDir | add-member NoteProperty Beta $beta -passthru

                $modifiedDirs += $modifiedDir
                }
            }

        if ($modifiedDirs)
            {
            $latest = $null
            $latest = ($modifiedDirs | Sort-Object Version -desc)[0]

            if ($latest.beta)
              {
              write-warning "FYI - Latest version of SmartSDR installed is a Beta version (v$($latest.Version))."
              }

            $latest.fullname
            }
        }
    }

function Get-FlexLibPath
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$false,
        ConfirmImpact="Low")]
    param()

    begin { }

    process
        {
        $flexDLL = $null
        $DLLdata = $null

        $latestPath = get-flexlatestfolderpath

        if ($latestPath)
            {
            $flexDLL = $latestpath + "\FlexLib.dll"

            write-verbose "Using: $flexDLL"

            if (test-path $flexDLL)
                {
                $DLLdata = [reflection.assemblyname]::getassemblyname($flexDLL)

                write-verbose "ProcessorArchitecture: $($DLLdata.ProcessorArchitecture)"

                if (($DLLdata.ProcessorArchitecture -ne "MSIL") -and (test-win64))  # x86 dll on 64 bit host?
                    {
                    write-verbose "Incompatible FlexLib - Wrong architecture!"

                    $moduleRoot = split-path (get-module -ListAvailable flexmodule).path

                    if (test-path ($moduleRoot + "\Lib\FlexLib.dll"))
                        {
                        # this is our last hope to find a compatible flexlib dll
                        write-verbose "Using DLL included with FlexModule."

                        $moduleRoot + "\Lib\FlexLib.dll"
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

    end { }
    }

function Import-FlexLib
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
            push-location (split-path $flexLibPath)
            add-type -path $flexLibPath
            pop-location
            }
        }
    else
        {
        throw "Unable to locate FlexRadio FlexLib DLL, or DLL is incompatible with this architecture!"
        }

    # [flex.smoothlake.FlexLib.api]::init()
    }
