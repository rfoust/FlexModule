# FlexPanadapter.ps1

function get-FlexPanadapter
    {
    [CmdletBinding(DefaultParameterSetName="p0")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [uint32]$StreamID
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

            if (-not $radioObj.panadapterlist)
                {
                write-warning "No panadapters found! SmartSDR may not be running."
                }

            $panadapters = $null

            if ($PSBoundParameters.ContainsKey('StreamID'))
                {
                $panadapters = $radioObj.PanadapterList | ? { $_.StreamID -eq $StreamID}
                }
            else
                {
                $panadapters = $radioObj.PanadapterList | sort StreamID
                }

            $panadapters
            }
        }

    end { }
    }


function set-FlexPanadapter
    {
    [CmdletBinding(DefaultParameterSetName="p0",
        SupportsShouldProcess=$true,
        ConfirmImpact="High")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1, ValueFromPipelineByPropertyName = $true)]
        [uint32]$StreamID,

        [Parameter(ParameterSetName="p0")]
        [bool]$AutoCenter,

        [Parameter(ParameterSetName="p0")]
        [int]$Average,

        [Parameter(ParameterSetName="p0")]
        [string]$Band,

        [Parameter(ParameterSetName="p0")]
        [double]$Bandwidth,

        [Parameter(ParameterSetName="p0")]
        [double]$CenterFreq,

        [Parameter(ParameterSetName="p0")]
        [double]$ClickTune,

        [Parameter(ParameterSetName="p0")]
        [int]$DAXIQChannel,

        [Parameter(ParameterSetName="p0")]
        [int]$FPS,

        [Parameter(ParameterSetName="p0")]
        [double]$HighDbm,

        [Parameter(ParameterSetName="p0")]
        [bool]$LoopA,

        [Parameter(ParameterSetName="p0")]
        [bool]$LoopB,

        [Parameter(ParameterSetName="p0")]
        [double]$LowDbm,

        [Parameter(ParameterSetName="p0")]
        [string]$Preamp,

        [Parameter(ParameterSetName="p0")]
        [double]$RFGain,

        [Parameter(ParameterSetName="p0")]
        [double]$RFGainHigh,

        [Parameter(ParameterSetName="p0")]
        [double]$RFGainLow,

        #[Parameter(ParameterSetName="p0")]
        #[double[]]$RFGainMarkers,

        [Parameter(ParameterSetName="p0")]
        [double]$RFGainStep,

        [Parameter(ParameterSetName="p0")]
        [string]$RXAnt,

        [Parameter(ParameterSetName="p0")]
        [bool]$WeightedAverage,

        [Parameter(ParameterSetName="p0")]
        [bool]$Wide,

        [Parameter(ParameterSetName="p0")]
        [string]$XVTR
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

            write-verbose "Radio connected: $($radioObj.connected)"

            if ($radioObj.Connected -eq $false)
                {
                throw "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."
                }

            if (-not $radioObj.panadapterlist)
                {
                write-warning "No panadapters found! SmartSDR may not be running."
                }

            $panadapter = get-FlexPanadapter -StreamID:$StreamID

            if (-not $panadapter)
                {
                throw "Panadapter StreamID $StreamID not found!"
                }

            if ($panadapter.count -ne 1)
                {
                throw "Internal error: Multiple panadapter entries were returned, this is unexpected."
                }

            if ($PSBoundParameters.ContainsKey('AutoCenter') -and ($AutoCenter -ne $panadapter.AutoCenter))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify AutoCenter"))
                    {
                    $panadapter.set_AutoCenter($AutoCenter)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Average') -and ($Average -ne $panadapter.Average))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Average"))
                    {
                    $panadapter.set_Average($Average)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Band') -and ($Band -ne $panadapter.Band))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Band"))
                    {
                    $panadapter.set_Band($Band)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Bandwidth') -and ($Bandwidth -ne $panadapter.Bandwidth))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Bandwidth"))
                    {
                    $panadapter.set_Bandwidth($Bandwidth)
                    }
                }

            if ($PSBoundParameters.ContainsKey('CenterFreq') -and ($CenterFreq -ne $panadapter.CenterFreq))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify CenterFreq"))
                    {
                    $panadapter.set_CenterFreq($CenterFreq)
                    }
                }

            if ($PSBoundParameters.ContainsKey('ClickTune') -and ($ClickTune -ne $panadapter.ClickTune))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify ClickTune"))
                    {
                    $panadapter.ClickTuneRequest($ClickTune)
                    }
                }

            if ($PSBoundParameters.ContainsKey('DAXIQChannel') -and ($DAXIQChannel -ne $panadapter.DAXIQChannel))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify DAXIQChannel"))
                    {
                    $panadapter.set_DAXIQChannel($DAXIQChannel)
                    }
                }

            if ($PSBoundParameters.ContainsKey('FPS') -and ($FPS -ne $panadapter.FPS))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify FPS"))
                    {
                    $panadapter.set_FPS($FPS)
                    }
                }

            if ($PSBoundParameters.ContainsKey('HighDbm') -and ($HighDbm -ne $panadapter.HighDbm))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify HighDbm"))
                    {
                    $panadapter.set_HighDbm($HighDbm)
                    }
                }

            if ($PSBoundParameters.ContainsKey('LoopA') -and ($LoopA -ne $panadapter.LoopA))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify LoopA"))
                    {
                    $panadapter.set_LoopA($LoopA)
                    }
                }

            if ($PSBoundParameters.ContainsKey('LoopB') -and ($LoopB -ne $panadapter.LoopB))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify LoopB"))
                    {
                    $panadapter.set_LoopB($LoopB)
                    }
                }

            if ($PSBoundParameters.ContainsKey('LowDbm') -and ($LowDbm -ne $panadapter.LowDbm))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify LowDbm"))
                    {
                    $panadapter.set_LowDbm($LowDbm)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Preamp') -and ($Preamp -ne $panadapter.Preamp))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Preamp"))
                    {
                    $panadapter.set_Preamp($Preamp)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RFGain') -and ($RFGain -ne $panadapter.RFGain))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RFGain"))
                    {
                    $panadapter.set_RFGain($RFGain)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RFGainHigh') -and ($RFGainHigh -ne $panadapter.RFGainHigh))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RFGainHigh"))
                    {
                    $panadapter.set_RFGainHigh($RFGainHigh)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RFGainLow') -and ($RFGainLow -ne $panadapter.RFGainLow))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RFGainLow"))
                    {
                    $panadapter.set_RFGainLow($RFGainLow)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RFGainStep') -and ($RFGainStep -ne $panadapter.RFGainStep))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RFGainStep"))
                    {
                    $panadapter.set_RFGainStep($RFGainStep)
                    }
                }

            if ($PSBoundParameters.ContainsKey('RXAnt') -and ($RXAnt -ne $panadapter.RXAnt))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify RXAnt"))
                    {
                    $panadapter.set_RXAnt($RXAnt)
                    }
                }

            if ($PSBoundParameters.ContainsKey('WeightedAverage') -and ($WeightedAverage -ne $panadapter.WeightedAverage))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify WeightedAverage"))
                    {
                    $panadapter.set_WeightedAverage($WeightedAverage)
                    }
                }

            if ($PSBoundParameters.ContainsKey('Wide') -and ($Wide -ne $panadapter.Wide))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify Wide"))
                    {
                    $panadapter.set_Wide($Wide)
                    }
                }

            if ($PSBoundParameters.ContainsKey('XVTR') -and ($XVTR -ne $panadapter.XVTR))
                {
                if ($pscmdlet.ShouldProcess($radioObj.Serial,"Modify XVTR"))
                    {
                    $panadapter.set_XVTR($XVTR)
                    }
                }
            }
        }

    end { }
    }

