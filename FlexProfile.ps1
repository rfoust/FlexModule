# FlexProfile.ps1

function get-FlexProfile
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
                write-warning "Not connected to $($radioObj.model): $($radioObj.serial). Use connect-flexradio to establish a new connection."

                continue
                }

            # start building the profile object

            # ProfileMicList
            foreach ($profile in $radioObj.ProfileMicList)
                {
                if ($profile -eq $null)
                    {
                    continue
                    }

                $profileObj = new-object psobject

                $profileObj | add-member NoteProperty -Name "ProfileType" -Value "Mic"
                $profileObj | add-member NoteProperty -Name "Name" -Value $profile

                if ($profile -eq $radioObj.profileMicSelection)
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $true
                    }
                else
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $false
                    }

                $profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
                $profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
                $profileObj
                }

            # ProfileTXList
            foreach ($profile in $radioObj.ProfileTXList)
                {
                if ($profile -eq $null)
                    {
                    continue
                    }

                $profileObj = new-object psobject

                $profileObj | add-member NoteProperty -Name "ProfileType" -Value "TX"
                $profileObj | add-member NoteProperty -Name "Name" -Value $profile

                if ($profile -eq $radioObj.profileTXSelection)
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $true
                    }
                else
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $false
                    }

                $profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
                $profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
                $profileObj
                }

            # ProfileDisplayList
            foreach ($profile in $radioObj.ProfileDisplayList)
                {
                if ($profile -eq $null)
                    {
                    continue
                    }

                $profileObj = new-object psobject

                $profileObj | add-member NoteProperty -Name "ProfileType" -Value "Display"
                $profileObj | add-member NoteProperty -Name "Name" -Value $profile

                if ($profile -eq $radioObj.profileDisplaySelection)
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $true
                    }
                else
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $false
                    }

                $profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
                $profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
                $profileObj
                }

            # ProfileGlobalList
            foreach ($profile in $radioObj.ProfileGlobalList)
                {
                if ($profile -eq $null)
                    {
                    continue
                    }

                $profileObj = new-object psobject

                $profileObj | add-member NoteProperty -Name "ProfileType" -Value "Global"
                $profileObj | add-member NoteProperty -Name "Name" -Value $profile

                if ($profile -eq $radioObj.profileGlobalSelection)
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $true
                    }
                else
                    {
                    $profileObj | add-member NoteProperty -Name "Selected" -Value $false
                    }

                $profileObj | add-member NoteProperty -Name "Serial" -Value $radioObj.serial
                $profileObj.PSObject.TypeNames.Insert(0,'FlexModule.Profile')
                $profileObj
                }
            
            }
        }

    end { }
    }

