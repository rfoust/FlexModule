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