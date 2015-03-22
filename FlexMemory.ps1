# FlexMemory.ps1

function get-FlexMemory
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [int]$Index
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

            if (-not $radioObj.MemoryList)
                {
                write-warning "No saved memories found or SmartSDR may not be running."
                }

            if ($PSBoundParameters.ContainsKey('Index') -and ($Index -ge 0))
                {
                $radioObj.MemoryList | ? { $_.index -eq $Index}
                }
            else
                {
                $radioObj.MemoryList | sort index
                }
            }
        }

    end { }
    }

function set-FlexMemory
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [int]$Index,

        [Parameter(ParameterSetName="p0")]
        [double]$Freq,

        [Parameter(ParameterSetName="p0")]
        [string]$Group,

        [Parameter(ParameterSetName="p0")]
        [string]$Mode,

        [Parameter(ParameterSetName="p0")]
        [string]$Name,

        [Parameter(ParameterSetName="p0")]
        [ValidateSet("Down","Simplex","Up")]
        [string]$OffsetDirection,

        [Parameter(ParameterSetName="p0")]
        [string]$Owner,

        [Parameter(ParameterSetName="p0")]
        [double]$RepeaterOffset,

        [Parameter(ParameterSetName="p0")]
        [int]$RFPower,

        [Parameter(ParameterSetName="p0")]
        [int]$RXFilterHigh,

        [Parameter(ParameterSetName="p0")]
        [int]$RFFilterLow,

        [Parameter(ParameterSetName="p0")]
        [int]$SquelchLevel,

        [Parameter(ParameterSetName="p0")]
        [bool]$SquelchOn,

        [Parameter(ParameterSetName="p0")]
        [int]$Step,

        [Parameter(ParameterSetName="p0")]
        [ValidateSet("Off","CTCSS_TX")]
        [string]$ToneMode,

        [Parameter(ParameterSetName="p0")]
        [string]$ToneValue
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

            $memory = get-FlexMemory -Index:$Index

            if (-not $memory)
                {
                throw "Memory index $Index not found!"
                }

            if ($memory.count -ne 1)
                {
                throw "Internal error: Multiple memory entries were returned, this is unexpected."
                }

            if ($PSBoundParameters.ContainsKey('Freq') -and ($Freq -ne $memory.Freq))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Freq on Index #$Index"))
                    {
                    $memory.set_Freq($Freq)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Group') -and ($Group -ne $memory.Group))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Group on Index #$Index"))
                    {
                    $memory.set_Group($Group)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Mode') -and ($Mode -ne $memory.Mode))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Mode on Index #$Index"))
                    {
                    $memory.set_Mode($Mode)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Name') -and ($Name -ne $memory.Name))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Name on Index #$Index"))
                    {
                    $memory.set_Name($Name)
                    }
                }

            if ($PSBoundParameters.ContainsKey('OffsetDirection') -and ($OffsetDirection -ne $memory.OffsetDirection))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify OffsetDirection on Index #$Index"))
                    {
                    $memory.set_OffsetDirection($OffsetDirection)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Owner') -and ($Owner -ne $memory.Owner))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Owner on Index #$Index"))
                    {
                    $memory.set_Owner($Owner)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RepeaterOffset') -and ($RepeaterOffset -ne $memory.RepeaterOffset))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RepeaterOffset on Index #$Index"))
                    {
                    $memory.set_RepeaterOffset($RepeaterOffset)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RFPower') -and ($RFPower -ne $memory.RFPower))
                {
                if ($RFPower -lt 0) { $RFPower = 0 }
                if ($RFPower -gt 100) { $RFPower = 100 }

                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RFPower on Index #$Index"))
                    {
                    $memory.set_RFPower($RFPower)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RXFilterHigh') -and ($RXFilterHigh -ne $memory.RXFilterHigh))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RXFilterHigh on Index #$Index"))
                    {
                    $memory.set_RXFilterHigh($RXFilterHigh)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RXFilterLow') -and ($RXFilterLow -ne $memory.RXFilterLow))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RXFilterLow on Index #$Index"))
                    {
                    $memory.set_RXFilterLow($RXFilterLow)
                    }
                }

            if ($PSBoundParameters.ContainsKey('SquelchLevel') -and ($SquelchLevel -ne $memory.SquelchLevel))
                {
                if ($SquelchLevel -lt 0) { $SquelchLevel = 0 }
                if ($SquelchLevel -gt 100) { $SquelchLevel = 100 }

                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify SquelchLevel on Index #$Index"))
                    {
                    $memory.set_SquelchLevel($SquelchLevel)
                    }
                }

            if ($PSBoundParameters.ContainsKey('SquelchOn') -and ($SquelchOn -ne $memory.SquelchOn))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify SquelchOn on Index #$Index"))
                    {
                    $memory.set_SquelchOn($SquelchOn)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Step') -and ($Step -ne $memory.Step))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Step on Index #$Index"))
                    {
                    $memory.set_Step($Step)
                    }
                }

            if ($PSBoundParameters.ContainsKey('ToneMode') -and ($ToneMode -ne $memory.ToneMode))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify ToneMode on Index #$Index"))
                    {
                    $memory.set_ToneMode($ToneMode)
                    }
                }

            if ($PSBoundParameters.ContainsKey('ToneValue') -and ($ToneValue -ne $memory.ToneValue))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify ToneValue on Index #$Index"))
                    {
                    $memory.set_ToneValue($ToneValue)
                    }
                }
            }
        }

    end { }
    }

function remove-FlexMemory
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="High")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [int]$Index
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

            $memories = get-FlexMemory -Index:$Index

            foreach ($memory in $memories)
                {
                if ($memory.Index)
                    {
                    if ($pscmdlet.ShouldProcess($radioObj.Serial,"Delete Memory #$($memory.index)"))
                        {
                        $memory.remove()
                        }
                    }
                }
            }
        }

    end { }
    }

function select-FlexMemory
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [int]$Index
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

            $memories = get-FlexMemory -Index:$Index

            foreach ($memory in $memories)
                {
                if ($memory.Index)
                    {
                    if ($pscmdlet.ShouldProcess($radioObj.Serial,"Select Memory #$($memory.index)"))
                        {
                        $memory.select()
                        }
                    }
                }
            }
        }

    end { }
    }
