function Test-Win64() {
	return [IntPtr]::size -eq 8
}
