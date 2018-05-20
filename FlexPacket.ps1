# FlexPacket.ps1

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
    $leftPad = 28   # 10 for date/time, 15 for source + padding + extra stuff
    #$dataLength = $data.length
    $maxDataWidth = $consoleWidth - $leftPad - 2    # the 3 is for the " : " in the prefix string, and subtract one for a right pad

    $firstLine = $true
    $dataStringIndex = 0        #starting point
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

# this is a packet sniffer function for flex radio packets
function Get-FlexPacket
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1)]
        [string]$LocalIP
        )

    begin { }

    process
        {
        if (-not $Serial)
            {
            $radios = get-FlexRadio

            if ($radios.count -eq 1)
                {
                write-verbose "One FlexRadio found. Using it."
                $Serial = $radios[0].serial
                }
            else
                {
                throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
                }
            }


        $radioObj = get-FlexRadio -Serial:$serial

        write-verbose "Serial: $($radioObj.serial)"

        if (-not $radioObj.serial)
            {
            continue
            }

        write-verbose "Radio connected: $($radioObj.connected)"

        displayTime
        displaySource "*"
        write-host "Press ESC to exit the packet sniffer." -foregroundcolor cyan

        <#
        $smartSDRdetected = $false
        $SmartSDRVersion = (get-process | ? { $_.processname -match "SmartSDR" }).productversion

        if ($SmartSDRVersion)
            {
            displayTime
            displaySource "*"
            write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
            $smartSDRdetected = $true
            }
        #>

        $remoteIP = $radioObj.ip

        if (-not $remoteIP)
            {
            throw "Unable to locate FlexRadio IP address!"
            }

        $fragment = $null
        $fragmentFound = $false

        displayTime
        displaySource "*"
        write-host "Expect packet sniffer delays if a high amount of network traffic is expected." -foregroundcolor cyan

        $pingHash = @{}
        $pingCount = 0

        #get-packet | ? { ($_.source -eq "192.168.1.133" -or $_.destination -eq "192.168.1.133") -and ($_.protocol -eq "TCP")} | % {
        get-packet -protocol flex -LocalIP:$LocalIP -remoteIP $remoteIP | ForEach-Object {
            $packet = $_

            if ((-not $packet) -or ($packet.length -le 0))
                {
                continue
                }

            <#
            if ($smartSDRdetected -eq $false)
                {
                $SmartSDRVersion = (get-process | ? { $_.processname -match "SmartSDR" }).productversion
                write-verbose "SmartSDRVersion: $SmartSDRVersion"

                if ($SmartSDRVersion)
                    {
                    displayTime
                    displaySource "*"
                    write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
                    $smartSDRdetected = $true
                    }
                }
            #>

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

            $packet -split '\n' | ForEach-Object { $_ -replace '^\x00*','' } | Where-Object { $_ -ne "" -and $_ -ne $null } | ForEach-Object {

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
                        write-host "Version: $packetSubData" -foregroundcolor green
                        break
                        }
                    "H"
                        {
                        displayTime
                        displaySource "Radio"
                        write-host "Handle received: [$packetSubData]" -foreground green
                        break
                        }
                    "C" # command sent
                        {
                        $sequence,$command = $packetSubData.split("|")

                        if ($command -match "^ping")
                            {
                            $pingHash[$sequence] = get-date
                            $pingCount++

                            if ($pingCount % 50 -eq 0)
                                {
                                displayTime
                                displaySource "*"
                                displayData "$pingCount keepalive pings have been seen."

                                displayTime
                                displaySource "*"

                                if ($pingHash.count)
                                    {
                                    displayData "$($pingHash.count) unacknowledged ping(s)."
                                    }
                                }

                            break
                            }

                        displayTime
                        displaySource "Local"
                        displayData "{$sequence} $command"
                        break
                        }
                    "R"
                        {
                        $sequence,$command = $packetSubData.split("|")

                        if ($pingHash[$sequence])
                            {
                            $pingHash.Remove($sequence)

                            break
                            }

                        displayTime
                        displaySource "RadioResponse"

                        displayData "{$sequence} $command"
                        break
                        }
                    "S"
                        {
                        displayTime
                        displaySource "RadioStatus"
                        $handle,$command = $packetSubData.split("|")
                        displayData "[$handle] $command"
                        break
                        }
                    "M"
                        {
                        displayTime
                        displaySource "RadioMessage"
                        $handle,$command = $packetSubData.split("|")

                        #switch ($handle)
                        #   {
                        #   # decode message number for severity
                        #   }
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

    end { }
    }

