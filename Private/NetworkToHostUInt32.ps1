function NetworkToHostUInt32 ($value) {
	# Takes a 4 byte array, switches it from big endian to little endian, and converts it to uint32.
	[Array]::Reverse($value)
	[BitConverter]::ToUInt32($value, 0)
}
