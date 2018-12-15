function Get-FlexCommand {
	[CmdletBinding()]
	param()

	Get-Module FlexModule -ListAvailable | ForEach-Object { $_.ExportedCommands.Values }
}
