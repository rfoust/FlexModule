# FlexUtil.ps1

function get-FlexControlLog
    {
    [CmdletBinding(DefaultParameterSetName="p0")]

    param(
        # sets screensaver to active slice receiver frequency
        [Parameter(ParameterSetName="p0")]
        [string]$FCLog = (join-path $env:AppData "FlexRadio Systems\LogFiles\SSDR_FCManager.log")
      )

    $lastDate = $null

    foreach ($line in (get-content $FCLog))
        {
        write-verbose "Raw line: $line"
        write-verbose "Line Length: $($line.length)"

        if ($line -and ($line.length -gt 0) -and ($line -match "^\S"))  # start with non-whitespace?
            {
            $line = $line -replace "M: ","M|"

            write-verbose "Initial split: $line"

            [datetime]$logEntryDate,[string]$logData = $line -split "\|"

            write-verbose "Date: $logEntryDate"
            write-verbose "LogData: $logData"

            # used if the prior line wrapped; wrapped lines won't have a date
            $lastDate = $logEntryDate

            $logEntry = new-object psobject

            $logEntry | add-member NoteProperty "Timestamp" $logEntryDate
            $logEntry | add-member NoteProperty "Data" $logData

            $logEntry
            }
        elseif ($lastDate -and ($line.length -gt 0))
            {
            $logEntry = new-object psobject

            $logEntry | add-member NoteProperty "Timestamp" $lastDate
            $logEntry | add-member NoteProperty "Data" $line.trimstart()

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
        [switch]$Clock,

        # sets screensaver to active slice receiver frequency
        [Parameter(ParameterSetName="p0")]
        [switch]$UTCClock,

        # sets screensaver to active slice receiver frequency
        [Parameter(ParameterSetName="p1")]
        [switch]$Frequency
        )

    begin { }

    process
        {
        $escKey = 27

        $originalNickName = (get-FlexRadio).NickName

        if ($Clock -or $UTCClock)
            {
            write-host "Keeping radio screensaver in sync with the current time. Press ESC to exit."

            while ($true)
                {
                # check and see if ESC was pressed
                if ($host.ui.RawUi.KeyAvailable)
                    {
                    $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")

                    if ($key.VirtualKeyCode -eq $ESCkey)
                        {
                        set-FlexRadio -NickName:$originalNickName

                        break
                        }
                    }

                if ($UTCClock)
                    {
                    $now = (get-date).ToUniversalTime().ToShortTimeString() + " UTC"
                    }
                else
                    {
                    $now = (get-date).ToShortTimeString()
                    }

                $last = (get-FlexRadio).NickName

                if ($now -ne $last)
                    {
                    set-FlexRadio -Screensaver "name" -nickname $now
                    }

                start-sleep -milliseconds 250
                }
            }
        elseif ($Frequency)
            {
            write-host "Keeping radio screensaver in sync with active slice receiver frequency. Press ESC to exit."

            while ($true)
                {
                # check and see if ESC was pressed
                if ($host.ui.RawUi.KeyAvailable)
                    {
                    $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")

                    if ($key.VirtualKeyCode -eq $ESCkey)
                        {
                        set-FlexRadio -NickName:$originalNickName

                        break
                        }
                    }

                $activeSlice = get-FlexSliceReceiver | ? { $_.Active -eq $true }

                if ($activeSlice)
                    {
                    $freqStr = "{0:N6}" -F $activeSlice.Freq
                    $freqStr = $freqStr.insert(($($freqStr).Length -3), ".")

                    #set-FlexRadio -Screensaver "name" -nickname $freqStr
                    set-FlexRadio -Screensaver "name" -nickname ([char]($activeSlice.index + 65) + ":" + $freqStr)
                    }
                else
                    {
                    set-FlexRadio -Screensaver "name" -nickname "NoActiveSlice"
                    }

                start-sleep -milliseconds 250
                }
            }
        }

    end { }
    }
