# FlexPanadapter.ps1

function get-FlexPanadapter
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

            if (-not $radioObj.panadapterlist)
                {
                write-warning "No panadapters found! SmartSDR may not be running."
                }

            $radioObj.panadapterlist
            }
        }

    end { }
    }


# this function needs work
function set-FlexPanadapter
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipeline = $true)]
        [ValidateScript({$_.serial})]  # must have serial number
        $RadioObject,

        [Parameter(ParameterSetName="p0",Position=0)]
        [bool]$ACCOn

        )

    begin { }

    process
        {
        foreach ($radio in $RadioObject)
            {
            if ($radio -eq $null)
                {
                continue
                }

            if ($radio.Connected -eq $false)
                {
                throw "Not connected to $($radio.model): $($radio.serial). Use connect-flexradio or get-flexradio | connect-flexradio to establish a new connection."
                }

            if (-not ($indexObj = $radio | findFlexRadioIndexNumber))
                {
                throw "Lost source radio object, try running get-flexradio again."
                }

            if ($PSBoundParameters.ContainsKey('AccOn') -and ($ACCOn -ne $radio.AccOn))
                {
                $global:FlexRadios[$indexObj.index].set_AccOn($AccOn)
                }
            }
        }

    end { }
    }

