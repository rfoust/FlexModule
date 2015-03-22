# FlexSlice.ps1

function get-FlexSliceReceiver
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
            if ($global:FlexRadios.count -eq 1)
                {
                write-verbose "One FlexRadio found. Using it."
                $Serial = $global:FlexRadios[0].serial
                }
            else
                {
                throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
                }
            }

        foreach ($radio in $Serial)
            {
            $radioObj = $global:FlexRadios | ? { $_.serial -eq $Serial }

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

            if (-not $radioObj.slicelist)
                {
                write-warning "No slices found! SmartSDR may not be running."
                }

            $radioObj.slicelist
            }
        }

    end { }
    }

function set-FlexSliceReceiver
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0")]
        [bool]$Lock

        )

    begin { }

    process
        {
        if (-not $Serial)
            {
            if ($global:FlexRadios.count -eq 1)
                {
                $radioObject = $global:FlexRadios[0]
                }
            else
                {
                throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
                }
            }
        else
            {
            $radioObject = $global:FlexRadios | ? { $_.serial -eq $Serial }
            }

        foreach ($radio in $Serial)
            {
            if ($radio -eq $null)
                {
                continue
                }

            if ($radio.Connected -eq $false)
                {
                throw "Not connected to $($radio.model): $($radio.serial). Use connect-flexradio or get-flexradio | connect-flexradio to establish a new connection."
                }

            if ($PSBoundParameters.ContainsKey('Lock') -and ($Lock -ne $radio.Lock))
                {
                $radio.set_Lock($Lock)
                }
            }
        }

    end { }
    }

