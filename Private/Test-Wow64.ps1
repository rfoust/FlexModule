function Test-Wow64() {
	return (Test-Win32) -and (test-path env:\PROCESSOR_ARCHITEW6432)
}
