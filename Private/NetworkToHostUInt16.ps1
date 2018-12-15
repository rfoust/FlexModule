function NetworkToHostUInt16 ($value) {
	# Takes a 2 byte array, switches it from big endian to little endian, and converts it to uint16.
	[Array]::Reverse($value)
	[BitConverter]::ToUInt16($value, 0)
}
