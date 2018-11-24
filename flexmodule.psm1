
. $PSScriptRoot\get-packet.ps1
. $PSScriptRoot\FlexRadio.ps1
. $PSScriptRoot\FlexPacket.ps1
. $PSScriptRoot\FlexLib.ps1
. $PSScriptRoot\FlexBackup.ps1
. $PSScriptRoot\FlexLog.ps1
. $PSScriptRoot\FlexMemory.ps1
. $PSScriptRoot\FlexProfile.ps1
. $PSScriptRoot\FlexSlice.ps1
. $PSScriptRoot\FlexPanadapter.ps1
. $PSScriptRoot\FlexUtil.ps1
. $PSScriptRoot\Smartlink.ps1

Import-FlexLib

[flex.smoothlake.flexlib.api]::Init()
[flex.smoothlake.flexlib.api]::ProgramName = "FlexModule"

# main functions
export-modulemember -function *-Flex*

# packet sniffer functions
export-modulemember -function get-FlexPacket
export-modulemember -function get-Packet

# helper functions
export-modulemember -function get-FlexLatestFolderPath
export-modulemember -function get-FlexControlLog
export-modulemember -function get-FlexCommand
export-modulemember -function start-FlexScreenSaver
export-modulemember -function Get-FlexLibPath
