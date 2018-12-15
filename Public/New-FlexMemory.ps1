function New-FlexMemory
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial
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

        foreach ($radio in $Serial)
            {
            $radioObj = get-FlexRadio -Serial:$radio

            write-verbose "Serial: $($radioObj.serial)"

            if (-not $radioObj.serial)
                {
                continue
                }

            write-verbose "Radio connected: $($radioObj.connected)"

            if ($radioObj.Connected -eq $false)
                {
                throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
                }

            $newMem = $null

            $newMem = new-object flex.smoothlake.flexlib.memory $radioObj


            if ($pscmdlet.ShouldProcess($radioObj.Serial,"Create New Memory"))
                {
                if ($newMem.RequestMemoryFromRadio())
                    {
                    while ($newMem.RadioAck -ne $true)
                        {
                        start-sleep -milliseconds 250
                        }

                    $newMem
                    }
                else
                    {
                    throw "Memory creation failed!"
                    }
                }
            }
        }

    end { }
    }