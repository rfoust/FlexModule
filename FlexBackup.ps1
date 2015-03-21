# FlexBackup.ps1

function export-FlexDatabase
    {
    [CmdletBinding(DefaultParameterSetName="p1",
        SupportsShouldProcess=$true,
        ConfirmImpact="Low")]
    param(
        [Parameter(ParameterSetName="p0",Position=0, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName="p1",Position=0, ValueFromPipelineByPropertyName = $true)]
        [string]$Serial,

        [Parameter(ParameterSetName="p0",Position=1)]
        [Parameter(ParameterSetName="p1",Position=1)]
        [string]$Path = $(convert-path .),     # default path is current working directory

        [Parameter(ParameterSetName="p0")]
        [Parameter(ParameterSetName="p1")]
        [switch]$UseUniqueFolders,      # Create subfolders for each radio - folder name will be serial number

        [Parameter(ParameterSetName="p1")]
        [switch]$All,

        [Parameter(ParameterSetName="p0")]
        [switch]$GlobalProfiles,

        [Parameter(ParameterSetName="p0")]
        [switch]$TXProfiles,

        [Parameter(ParameterSetName="p0")]
        [switch]$Memories,

        [Parameter(ParameterSetName="p0")]
        [switch]$BandPersistence,

        [Parameter(ParameterSetName="p0")]
        [switch]$ModePersistence,

        [Parameter(ParameterSetName="p0")]
        [switch]$GlobalPersistence,

        [Parameter(ParameterSetName="p0")]
        [switch]$TNFS,

        [Parameter(ParameterSetName="p0")]
        [switch]$XVTRS
        )

    begin
        {
        write-verbose "Export Path: $Path"

        if (-not (test-path $path))
            {
            throw "Invalid path specified: $Path"
            }

        if (($global:FlexRadios.count -gt 1) -and ($UseUniqueFolders -eq $false))
            {
            write-warning "Multiple FlexRadios found, consider using the -UseUniqueFolders switch to keep backup files separated!"
            }
        }

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
                throw "Specify radio to use by serial number with -Serial argument, or use pipeline."
                }
            }

        foreach ($radio in $serial)
            {
            $radioObj = $global:FlexRadios | ? { $_.serial -eq $serial }

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

            if ($UseUniqueFolders)
                {
                $path = join-path $path $radioObj.serial

                write-verbose "Using unique subfolder: $path"

                if (-not (test-path $path))
                    {
                    [void](mkdir $path)
                    }
                }

            # get saved profiles
            $flexProfiles = get-FlexProfile -Serial $radioObj.serial

            # build metadata file
            $metaFile = "meta_data"
            $metaFullPath = join-path $path $metaFile

            write-verbose "Metadata file: $metaFullPath"

            $metaArr = @()
            $exportMemories = $false

            # todo: need to correctly build the metadata parameters for profiles and memories.

            if (($pscmdlet.parametersetname -eq "p1") -or $GlobalProfiles)  # p1 = backup everything
                {
                $globalProfilesToUse = $null

                $globalProfilesToUse = $flexProfiles | ? { $_.ProfileType -eq "Global" }

                $metaString = "GLOBAL_PROFILES^"

                foreach ($globalProfile in $globalProfilesToUse)
                    {
                    if (($globalProfile.Name -ne "") -and ($globalProfile -ne $null))
                        {
                        $metaString += $globalProfile.Name + "^"
                        }
                    }

                write-verbose "Global profile string: $metaString"

                $metaArr += $metaString
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $TXProfiles)
                {   
                $txProfilesToUse = $null

                $txProfilesToUse = $flexProfiles | ? { ($_.ProfileType -eq "TX") -and ($_.Name -notmatch "^RadioSport|^Default|\*") }

                $metaString = "TX_PROFILES^"

                foreach ($txProfile in $txProfilesToUse)
                    {
                    if (($txProfile.Name -ne "") -and ($txProfile -ne $null))
                        {
                        $metaString += $txProfile.Name + "^"
                        }
                    }

                write-verbose "TX profile string: $metaString"

                $metaArr += $metaString
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $Memories)
                {
                $exportMemories = $true

                $memoryOwners = get-FlexMemory -Serial $radioObj.Serial | group Owner | % { $_.Name }

                $metaString = "MEMORIES^"

                foreach ($owner in $memoryOwners)
                    {
                    if (($owner -ne "") -and ($owner -ne $null))
                        {
                        # no idea what the pipe '|' char is used for, but looks like it needs to be there.
                        $metaString += $owner + "|^"
                        }
                    }

                write-verbose "Memory profile string: $metaString"

                $metaArr += $metaString
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $BandPersistence)
                {
                $metaArr += "BAND_PERSISTENCE^"
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $ModePersistence)
                {
                $metaArr += "MODE_PERSISTENCE^"
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $GlobalPersistence)
                {
                $metaArr += "GLOBAL_PERSISTENCE^"
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $TNFS)
                {
                $metaArr += "TNFS^"
                }
            if (($pscmdlet.parametersetname -eq "p1") -or $XVTRS)
                {
                $metaArr += "XVTRS^"
                }

            # fyi: this will overwrite the existing file if one exists.
            $metaArr | out-file $metaFullPath -encoding ascii

            write-verbose "ExportMemories: $exportMemories"

            if ($pscmdlet.ShouldProcess($radioObj.Serial,"Export Database to File"))
                {
                $radioObj.ReceiveSSDRDatabaseFile($metaFullPath,$(split-path $metaFullPath),$exportMemories)

                # lets sleep to be sure the backup has begun since the function is a backgrounded process.
                start-sleep 1

                while ($radioObj.DatabaseExportComplete -ne $true)  # should we add a timeout? if so, how long?
                    {
                    start-sleep 1
                    }

                rm $metaFullPath

                $radioObj | select Model,Serial,DatabaseExportComplete,DatabaseExportException
                }
            }
        }

    end { }
    }

