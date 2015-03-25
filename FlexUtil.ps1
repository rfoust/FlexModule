# FlexUtil.ps1

function get-FlexControlLog
    {
    $AppData = $env:AppData

    $FCLog = join-path $AppData "FlexRadio Systems\LogFiles\SSDR_FCManager.log"

    foreach ($line in (get-content $FCLog))
        {
        if ($line)
            {
            $line = $line -replace "M: ","M|"

            [datetime]$logEntryDate,$logData = $line -split "\|"

            $logEntry = new-object psobject

            $logEntry | add-member NoteProperty "Timestamp" $logEntryDate
            $logEntry | add-member NoteProperty "Data" $logData

            $logEntry
            }
        }
    }

function get-FlexCommand
    {
    Get-Command | ? { $_.name -like "*-Flex*" }
    }