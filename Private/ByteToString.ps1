function ByteToString ($value) {
	# Takes a byte array, switches it from big endian to little endian, and converts it to a string.
	$AsciiEncoding = new-object system.text.asciiencoding
	$AsciiEncoding.GetString($value)
}
