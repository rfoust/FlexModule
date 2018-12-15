function Add-FlexWanServer($event) {
	$global:FlexWan = $event
	$global:WanFlexRadios = @()
	$global:WanFlexRadios += ($event.SourceArgs)[0] | ForEach-Object { $_ }
}
