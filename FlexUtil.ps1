# FlexUtil.ps1

function get-FlexControlLog
    {
    $AppData = $env:AppData

    $FCLog = join-path $AppData "FlexRadio Systems\LogFiles\SSDR_FCManager.log"

    foreach ($line in (get-content $FCLog))
        {
        if ($line)
            {
            $line = $line -replace "M: ","M|"

            [datetime]$logEntryDate,$logData = $line -split "\|"

            $logEntry = new-object psobject

            $logEntry | add-member NoteProperty "Timestamp" $logEntryDate
            $logEntry | add-member NoteProperty "Data" $logData

            $logEntry
            }
        }
    }

function get-FlexCommand
    {
    Get-Command | ? { $_.name -like "*-Flex*" }
    }

function start-FlexScreenSaver
    {
    [CmdletBinding(DefaultParameterSetName="p0")]

    param(
        # sets screensaver to active slice receiver frequency
        [Parameter(ParameterSetName="p0")]
        [switch]$Frequency
        )

    begin { }

    process 
        {
        if ($Frequency)
            {
            write-host "Keeping radio screensaver in sync with active slice receiver frequency. Press Ctrl-C to abort."

            while ($true)
                {
                $activeSlice = get-FlexSliceReceiver | ? { $_.Active -eq $true }

                if ($activeSlice)
                    {
                    $freqStr = "{0:N6}" -F $activeSlice.Freq
                    $freqStr = $freqStr.insert(($($freqStr).Length -3), ".")

                    set-FlexRadio -Screensaver "name" -nickname $freqStr
                    }

                start-sleep -milliseconds 250
                }
            }
        }

    end { }
    }