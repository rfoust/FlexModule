# FlexRadio.ps1

# note: serial number (property name "serial") should be the primary identifier for each radio
# there is a global variable $global:flexradios that will contain all flex radios found
# the various module cmdlets should be able to get/set on that object by finding a matching serial number.

function get-FlexRadio
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0")]
        [switch]$Discover
        )

    begin { }

    process 
        {
        $count = 0
        $found = $false
        $AllRadios = @()

        while (($count -le 10) -and !$found)
            {
            # try to discover FlexRadios on the network
            if ($discover -or (-not $global:flexradios))
                {
                $global:FlexRadios = [flex.smoothlake.flexlib.api]::RadioList
                }

            if (-not $global:flexradios)
                {
                write-verbose "No FlexRadios found, searching ($count of 10) ..."

                start-sleep -milliseconds 250
                $count++
                }
            else
                {
                $found = $true
                }
            }

        if ($Serial)
            {
            $global:FlexRadios | ? { $_.serial -eq $Serial }
            }
        elseif ($global:FlexRadios)
            {
            # using for loop to prevent modified collection exception when using pipeline
            for ($i = 0; $i -lt $global:FlexRadios.count; $i++)
                {
                $global:FlexRadios[$i]
                }
            }
        }

    end { }
    }

<# - no longer used
function findFlexRadioIndexNumber
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipeline = $true)]
        [ValidateScript({$_.serial})]  # must have serial number
        $RadioObject
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

            for ($loop = 0; $loop -le ($global:flexradios.count - 1); $loop++)
                {
                if ($global:flexradios[$loop].serial -eq $radio.serial)
                    {
                    $radioObj = new-object psobject

                    $radioObj | add-member -MemberType NoteProperty -Name "Serial" -Value $radio.serial
                    $radioObj | add-member -MemberType NoteProperty -Name "Index" -Value $loop

                    $radioObj
                    }
                }
            }
        }

    end { }
    }
#>

function connect-FlexRadio
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

            if ($pscmdlet.ShouldProcess($radioObj.Serial,"Connect to Radio"))
                {
                $result = $radioObj.connect()

                if ($result -eq $false)
                    {
                    write-warning "$($radioObj.serial) : Connect() result was False, unable to connect to radio."
                    }
                else
                    {
                    $count = 0

                    while ($count -lt 5)
                        {
                        if ($radioObj.Connected -eq $true)
                            {
                            $radioObj

                            break
                            }

                        $count++

                        start-sleep -milliseconds 250
                        }
                    }
                }
            }
        }

    end { }
    }

function disconnect-FlexRadio
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

            write-verbose "Disconnecting radio ..."

            if ($pscmdlet.ShouldProcess($radioObj.Serial,"Disconnect from Radio"))
                {
                $radioObj.disconnect()

                start-sleep -milliseconds 500

                $count = 0

                while ($count -lt 5)
                    {
                    if ($radioObj.Connected -eq $false)
                        {
                        write-verbose "Radio disconnected."
                        $radioObj

                        break
                        }

                    $count++

                    start-sleep -milliseconds 500
                    }
                }
            }
        }

    end { }
    }

