# FlexSlice.ps1

function get-FlexSliceReceiver
    {
    [CmdletBinding(DefaultParameterSetName="p0")]
    
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName="p1",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName="p1",Position=1, ValueFromPipelineByPropertyName = $true)]
        [int]$Index,

        [Parameter(ParameterSetName="p0")]
        [switch]$Active,

        [Parameter(ParameterSetName="p1")]
        [switch]$Inactive
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

            if (-not $radioObj.slicelist)
                {
                write-warning "No slices found! SmartSDR may not be running."
                }

            $slices = $null

            if ($PSBoundParameters.ContainsKey('Index') -and ($Index -ge 0))
                {
                $slices = $radioObj.SliceList | ? { $_.index -eq $Index}
                }
            else
                {
                $slices = $radioObj.SliceList | sort index
                }

            if ($PSBoundParameters.ContainsKey('Active'))
                {
                $slices = $slices | ? { $_.Active -eq $true }
                }
            elseif ($PSBoundParameters.ContainsKey('Inactive'))
                {
                $slices = $slices | ? { $_.Active -eq $false }
                }

            $slices
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

