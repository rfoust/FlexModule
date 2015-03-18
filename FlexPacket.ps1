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
function get-flexpacket
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        $serial,

        [Parameter(ParameterSetName="p0",Position=1)]
        [string]$LocalIP
        )

    begin { }

    process
        {
        if (-not $serial)
            {
            if ($global:FlexRadios.count -eq 1)
                {
                write-verbose "One FlexRadio found. Using it."
                $serial = $global:FlexRadios[0].serial
                }
            else
                {
                throw "Specify radio to use by serial number with -serial argument, or use pipeline."
                }
            }


        $radioObj = $global:FlexRadios | ? { $_.serial -eq $serial }

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

        #get-packet | ? { ($_.source -eq "192.168.1.133" -or $_.destination -eq "192.168.1.133") -and ($_.protocol -eq "TCP")} | % {
        get-packet -protocol flex -LocalIP:$LocalIP -remoteIP $remoteIP | % {
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

            $packet -split '\n' | % { $_ -replace '^\x00*','' } | ? { $_ -ne "" -and $_ -ne $null } | % {

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
                        write-host "Version $($packetSubData)" -foregroundcolor green
                        break
                        }
                    "H"
                        {
                        displayTime
                        displaySource "Radio"
                        write-host "Handle received: $($packetSubData)" -foreground green
                        break
                        }
                    "C" # command sent
                        {
                        displayTime
                        displaySource "Local"
                        $sequence,$command = $packetSubData.split("|")
                        displayData "#$sequence - $command"
                        break
                        }
                    "R"
                        {
                        displayTime
                        displaySource "RadioResponse"
                        $sequence,$command = $packetSubData.split("|")
                        displayData "#$sequence - $command"
                        break
                        }
                    "S"
                        {
                        displayTime
                        displaySource "RadioStatus"
                        $handle,$command = $packetSubData.split("|")
                        displayData "($handle) - $command"
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

