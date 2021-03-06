function Get-FlexPacket {
	[CmdletBinding(DefaultParameterSetName = "p0",
		ConfirmImpact = "Low")]
	param(
		[Parameter(ParameterSetName = "p0", Position = 0)]
		[string]$LocalIP,

		[Parameter(ParameterSetName = "p0", Position = 0)]
		[string]$RemoteIP,

		[Parameter(ParameterSetName = "p0", Position = 0)]
		[string]$Protocol = "all",

		[Parameter(ParameterSetName = "p0", Position = 0)]
		[int]$Seconds = 0,

		[Parameter(ParameterSetName = "p0", Position = 0)]
		[switch]$ResolveHosts,

		[Parameter(ParameterSetName = "p0", Position = 0)]
		[switch]$Statistics,

		[Parameter(ParameterSetName = "p0", Position = 0)]
		[switch]$silent
	)

	$packetCount = 0

	$starttime = get-date
	$byteIn = new-object byte[] 4
	$byteOut = new-object byte[] 4
	# $byteData = new-object byte[] 4096  # size of data
	#$byteData = new-object byte[] 65536  # size of data
	$byteData = new-object byte[] 750  # size of data - too large and we won't process packets fast enough

	$byteIn[0] = 1  # this enables promiscuous mode (ReceiveAll)

	# TCP Control Bits
	$TCPFIN = [byte]0x01
	$TCPSYN = [byte]0x02

	$TCPRST = [byte]0x04
	$TCPPSH = [byte]0x08
	$TCPACK = [byte]0x10
	$TCPURG = [byte]0x20

	$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$prp = new-object System.Security.Principal.WindowsPrincipal($wid)
	$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	$IsAdmin = $prp.IsInRole($adm)

	if (-not $IsAdmin) {
		throw "Launch Powershell with elevated (administrator) rights and try again."
	}

	if (!$localIP) {
		$LocalIP = (Get-NetRoute | Where-Object –FilterScript {$_.NextHop -Ne "::" -and $_.NextHop -ne "0.0.0.0" -and ($_.NextHop.SubString(0, 6) -ne "fe80::")} | Get-NetAdapter | Get-NetIPAddress -AddressFamily IPv4).IpAddress

		if ($LocalIP -is [array]) {
			throw "Multiple local IP addresses found. Use the -LocalIP option to specify the local IP address to use."
		}
		elseif (!$LocalIP) {
			throw "Unable to determine local IP address. Use the -LocalIP option to specify the local IP address to use."
		}
	}

	write-verbose "Using IPv4 Address: $LocalIP"

	# open a socket -- Type should be Raw, and ProtocolType has to be IP for promiscuous mode, otherwise iocontrol will fail below.
	$socket = new-object system.net.sockets.socket([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::IP)

	# this tells the socket to include the IP header
	$socket.setsocketoption("IP", "HeaderIncluded", $true)

	# $socket.dontfragment = $true

	# make the buffer big or we'll drop packets.
	$socket.ReceiveBufferSize = 500000000	# 500mb
	#$socket.SendBufferSize = 8192000

	$bufferWarning = $socket.ReceiveBufferSize * .75
	$bufferError = $socket.ReceiveBufferSize * .95
	$warningNotified = $false
	$errorNotified = $false

	$ipendpoint = new-object system.net.ipendpoint([net.ipaddress]"$localIP", 0)
	$socket.bind($ipendpoint)

	# this enables promiscuous mode
	[void]$socket.iocontrol([net.sockets.iocontrolcode]::ReceiveAll, $byteIn, $byteOut)

	# write-host "Press ESC to stop the packet sniffer ..." -fore yellow

	$escKey = 27
	$running = $true
	$packets = @()  # this will hold all packets for later analysis

	$smartSDRdetected = $false
	$DAXdetected = $false
	$CATdetected = $false

	while ($running) {
		if ($Seconds -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Seconds))) { # if user-specified timeout has expired
			break
		}

		if ($smartSDRdetected -eq $false -and $protocol -eq "flex") {
			$SmartSDRVersion = (get-process | Where-Object { $_.processname -eq "SmartSDR" }).productversion

			if ($SmartSDRVersion) {
				write-verbose "SmartSDRVersion: $SmartSDRVersion"

				displayTime
				displaySource "*"
				write-host "SmartSDR detected, version $SmartSDRVersion." -foregroundcolor cyan
				$smartSDRdetected = $true
			}
		}

		if ($DAXdetected -eq $false -and $protocol -eq "flex") {
			$DAXversion = (get-process | Where-Object { $_.processname -eq "DAX" }).productversion

			if ($DAXversion) {
				write-verbose "DAXversion: $DAXversion"

				displayTime
				displaySource "*"
				write-host "DAX detected, version $DAXversion." -foregroundcolor cyan
				$DAXdetected = $true
			}
		}

		if ($CATdetected -eq $false -and $protocol -eq "flex") {
			$CATversion = (get-process | Where-Object { $_.processname -eq "Cat" }).productversion

			if ($CATversion) {
				write-verbose "CATversion: $CATversion"

				displayTime
				displaySource "*"
				write-host "CAT detected, version $CATversion." -foregroundcolor cyan
				$CATdetected = $true
			}
		}

		if (-not $socket.Available) { # see if any packets are in the queue
			start-sleep -milliseconds 500

			continue
		}

		++$packetCount

		if ($packetCount % 1000 -eq 0) {
			write-verbose "Processed $packetCount packets, bytes available to read: $($socket.available)"
		}

		if ((-not $warningNotified) -and ($socket.Available -ge $bufferWarning)) {
			$warningNotified = $true

			displayTime
			displaySource "*"
			write-host "75% of socket buffer has been used. Unable to keep up with incoming network data. $($socket.available)" -foregroundcolor yellow
		}

		if ((-not $errorNotified) -and ($socket.Available -ge $bufferError) -and $warningNotified) {
			$errorNotified = $true

			displayTime
			displaySource "*"
			write-host "95% of socket buffer has been used! Packet loss is expected now. $($socket.available)" -foregroundcolor red
		}

		# $stream = [system.io.bufferedstream]([system.net.sockets.NetworkStream]($socket), 8192)

		# receive data
		$rcv = $null

		try {
			$rcv = $socket.receive($byteData, 0, $byteData.length, [net.sockets.socketflags]::None)
		}
		catch { }

		if (-not $rcv) {
			continue
		}

		# decode the header (see RFC 791 or this will make no sense)
		$MemoryStream = new-object System.IO.MemoryStream($byteData, 0, $rcv)
		$BinaryReader = new-object System.IO.BinaryReader($MemoryStream)
		# $BinaryReader = new-object System.IO.BinaryReader($stream)

		# $byteArr = $null
		# $byteArr = $BinaryReader.ReadBytes(10)

		# First 8 bits of IP header contain version & header length
		$VersionAndHeaderLength = $BinaryReader.ReadByte()
		# $VersionAndHeaderLength = $byteArr[0]

		# Next 8 bits contain the TOS (type of service)
		$TypeOfService = $BinaryReader.ReadByte()
		# $TypeOfService = $byteArr[1]

		# total length of header and payload
		$TotalLength = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
		# $TotalLength = NetworkToHostUInt16 $byteArr[2..3]

		$Identification = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
		# $Identification = NetworkToHostUInt16 $byteArr[4..5]
		$FlagsAndOffset = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
		# $FlagsAndOffset = NetworkToHostUInt16 $byteArr[6..7]
		$TTL = $BinaryReader.ReadByte()
		# $TTL = $byteArr[8]
		$ProtocolNumber = $BinaryReader.ReadByte()
		# $ProtocolNumber = $byteArr[9]
		$Checksum = [Net.IPAddress]::NetworkToHostOrder($BinaryReader.ReadInt16())

		$SourceIPAddress = $BinaryReader.ReadUInt32()
		$SourceIPAddress = [System.Net.IPAddress]$SourceIPAddress
		$DestinationIPAddress = $BinaryReader.ReadUInt32()
		$DestinationIPAddress = [System.Net.IPAddress]$DestinationIPAddress
		<#
		# abort if not a packet we're looking for
		if (($Protocol -eq "flex") -and ($ProtocolNumber -ne 6) -or
				(($SourceIPAddress -ne $remoteIP -or
				$DestinationIPAddress -ne $remoteIP)))
			{
			$BinaryReader.Close()
			$memorystream.Close()

			continue
			}
#>
		# Get the IP version number from the "left side" of the Byte
		$ipVersion = [int]"0x$(('{0:X}' -f $VersionAndHeaderLength)[0])"

		# Get the header length by getting right 4 bits (usually will be 5, as in 5 32 bit words)
		# multiplying by 4 converts from words to octets which is what TotalLength is measured in
		$HeaderLength = [int]"0x$(('{0:X}' -f $VersionAndHeaderLength)[1])" * 4

		if ($HeaderLength -gt 20) { # if header includes Options (is gt 5 octets long)
			[void]$BinaryReader.ReadBytes($HeaderLength - 20)  # should probably do something with this later
		}

		$Data = ""
		$TCPFlagsString = @()  # make this an array
		$TCPWindow = ""
		$SequenceNumber = ""

		switch ($ProtocolNumber) { # see http://www.iana.org/assignments/protocol-numbers
			1 {
				# ICMP
				$protocolDesc = "ICMP"

				$sourcePort = [uint16]0
				$destPort = [uint16]0
				break
			}
			2 {
				# IGMP
				$protocolDesc = "IGMP"
				$sourcePort = [uint16]0
				$destPort = [uint16]0
				$IGMPType = $BinaryReader.ReadByte()
				$IGMPMaxRespTime = $BinaryReader.ReadByte()
				$IGMPChecksum = [System.Net.IPAddress]::NetworkToHostOrder($BinaryReader.ReadInt16())
				$Data = ByteToString $BinaryReader.ReadBytes($TotalLength - ($HeaderLength - 32))
				break
			}
			6 {
				# TCP
				$protocolDesc = "TCP"

				$sourcePort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
				$destPort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
				$SequenceNumber = NetworkToHostUInt32 $BinaryReader.ReadBytes(4)
				$AckNumber = NetworkToHostUInt32 $BinaryReader.ReadBytes(4)
				$TCPHeaderLength = [int]"0x$(('{0:X}' -f $BinaryReader.ReadByte())[0])" * 4  # reads Data Offset + 4 bits of Reserve (ignored)

				$TCPFlags = $BinaryReader.ReadByte()  # this will also contain 2 bits of Reserve on the left, but we can just ignore them.

				switch ($TCPFlags) {
					{ $_ -band $TCPFIN } { $TCPFlagsString += "FIN" }
					{ $_ -band $TCPSYN } { $TCPFlagsString += "SYN" }
					{ $_ -band $TCPRST } { $TCPFlagsString += "RST" }
					{ $_ -band $TCPPSH } { $TCPFlagsString += "PSH" }
					{ $_ -band $TCPACK } { $TCPFlagsString += "ACK" }
					{ $_ -band $TCPURG } { $TCPFlagsString += "URG" }
				}

				$TCPWindow = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
				$TCPChecksum = [System.Net.IPAddress]::NetworkToHostOrder($BinaryReader.ReadInt16())
				$TCPUrgentPointer = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)

				if ($TCPHeaderLength -gt 20) { # get to start of data
					[void]$BinaryReader.ReadBytes($TCPHeaderLength - 20)
				}

				# if SYN flag is set, sequence number is initial sequence number, and therefore the first
				# octet of the data is ISN + 1.
				if ($TCPFlags -band $TCPSYN) {
					$ISN = $SequenceNumber
					#$SequenceNumber = $BinaryReader.ReadBytes(1)
					[void]$BinaryReader.ReadBytes(1)
				}

				$Data = ByteToString $BinaryReader.ReadBytes($TotalLength - ($HeaderLength + $TCPHeaderLength))
				break
			}
			17 {
				# UDP
				$protocolDesc = "UDP"

				$sourcePort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
				$destPort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
				$UDPLength = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
				[void]$BinaryReader.ReadBytes(2)
				# subtract udp header length (2 octets) and convert octets to bytes.
				$byteLength = ($UDPLength - 2) * 4
				if ($byteLength -ge 0) { # was seeing exceptions about negative numbers from ReadBytes() for some reason
					$Data = ByteToString $BinaryReader.ReadBytes($byteLength)
				}

				break
			}
			default {
				$protocolDesc = "Other ($_)"
				$sourcePort = 0
				$destPort = 0
				
				break
			}
		}

		$BinaryReader.Close()
		$memorystream.Close()

		if ($ResolveHosts) { # resolve IP addresses to hostnames
			# GetHostEntry is horribly slow on failed lookups, so I'm not using it
			# $DestinationHostName = ([System.Net.DNS]::GetHostEntry($DestinationIPAddress.IPAddressToString)).Hostname
			# $SourceHostName = ([System.Net.DNS]::GetHostEntry($SourceIPAddress.IPAddressToString)).Hostname

			$DestinationHostName = ResolveIP($DestinationIPAddress)
			$SourceHostName = ResolveIP($SourceIPAddress)
		}

		# now throw the stuff we consider important into a psobject
		# $ipObject = new-object psobject

		if ($Protocol -eq "all" -or $Protocol -eq $protocolDesc) {
			$packet = [PSCustomObject]@{
				Destination = $DestinationIPAddress
				Source      = $SourceIPAddress
				Version     = $ipVersion
				Protocol    = $protocolDesc
				Sequence    = $SequenceNumber
				Window      = $TCPWindow
				DestPort    = $destPort
				SourcePort  = $sourcePort
				Flags       = $TCPFlagsString
				Data        = $Data
				Time        = (Get-Date)
			}

			<#
			$packet = new-object psobject

			$packet | add-member noteproperty Destination $DestinationIPAddress
			if ($ResolveHosts) { $packet | add-member noteproperty DestinationHostName $DestinationHostName }
			$packet | add-member noteproperty Source $SourceIPAddress
			if ($ResolveHosts) { $packet | add-member noteproperty SourceHostName $SourceHostName }
			$packet | add-member noteproperty Version $ipVersion
			$packet | add-member noteproperty Protocol $protocolDesc
			$packet | add-member noteproperty Sequence $SequenceNumber
			$packet | add-member noteproperty Window $TCPWindow
			$packet | add-member noteproperty DestPort $destPort
			$packet | add-member noteproperty SourcePort $sourcePort
			$packet | add-member noteproperty Flags $TCPFlagsString
			$packet | add-member noteproperty Data $Data
			$packet | add-member noteproperty Time (get-date)
			#>

			# $packets += $packet  # add this packet to the array

			if (-not $Silent) {
				$packet
			}
		}
		# creating psobject (above) is way too slow for real time packets
		elseif (($Protocol -eq "flex") -and ($protocolDesc -eq "TCP") -and
			($SourceIPAddress -eq $remoteIP -or
				$DestinationIPAddress -eq $remoteIP)) {
			$data
		}
	}

	# calculate statistics
	if ($Statistics) {
		$activity = "Analyzing network trace"

		# calculate elapsed time
		# Using this logic, the beginning time is when the first packet is received,
		#  not when packet capturing is started. That may or may not be ideal depending
		#  on what you're trying to measure.
		write-progress $activity "Counting packets"
		$elapsed = $packets[-1].time - $packets[0].time

		#calculate packets per second
		write-progress $activity "Calculating elapsed time"
		$pps = $packets.count / (($packets[-1].time - $packets[0].time).totalseconds)
		$pps = "{0:N4}" -f $pps

		# Calculating protocol distribution
		write-progress $activity "Calculating protocol distribution"
		$protocols = $packets | Sort-Object protocol | Group-Object protocol | Sort-Object count -descending | Select-Object Count, @{name = "Protocol"; Expression = {$_.name}}

		# Calculating source port distribution
		write-progress $activity "Calculating source port distribution"
		$sourceport = $packets | Sort-Object sourceport | Group-Object sourceport | Sort-Object count -descending | Select-Object Count, @{name = "Port"; Expression = {$_.name}}

		# Calculating destination distribution
		write-progress $activity "Calculating destination distribution"
		$destinationlist = $packets | Sort-Object Destination | Select-Object Destination

		# Calculating destination port distribution
		write-progress $activity "Calculating destination port distribution"
		$destinationport = $packets | Sort-Object destport | Group-Object destport | Sort-Object count -descending | Select-Object Count, @{name = "Port"; Expression = {$_.name}}

		# Building source list
		write-progress $activity "Building source list"
		$sourcelist = $packets | Sort-Object source | Select-Object Source

		# Building source IP list
		write-progress $activity "Building source IP list"
		$ips = $sourcelist | Group-Object source | Sort-Object count -descending | Select-Object Count, @{Name = "IP"; Expression = {$_.Name}}

		# Build destination IP list
		write-progress $activity "Building destination IP list"
		$ipd = $destinationlist | Group-Object destination | Sort-Object count -descending | Select-Object Count, @{Name = "IP"; Expression = {$_.Name}}

		# Presenting data
		write-progress $activity "Compiling results"
		$protocols = $protocols | Select-Object Count, Protocol, @{Name = "Percentage"; Expression = {"{0:P4}" -f ($_.count / $packets.count)}}

		$destinationport = $destinationport | Select-Object Count, Port, @{Name = "Percentage"; Expression = {"{0:P4}" -f ($_.count / $packets.count)}}

		$sourceport = $sourceport | Select-Object Count, Port, @{Name = "Percentage"; Expression = {"{0:P4}" -f ($_.count / $packets.count)}}

		if ($ResolveHosts) {
			write-progress $activity "Resolving IPs"

			# add hostnames to the new object(s)
			foreach ($destination in $ipd) {
				$destination | add-member noteproperty "Host" $(ResolveIP([system.net.ipaddress]$destination.IP))
			}
			foreach ($source in $ips) {
				$source | add-member noteproperty "Host" $(ResolveIP([system.net.ipaddress]$source.IP))
			}
		}

		write-progress $activity "Compiling results"
		$destinations = $ipd | Select-Object Count, IP, Host, @{Name = "Percentage"; Expression = {"{0:P4}" -f ($_.count / $packets.count)}}
		$sources = $ips | Select-Object Count, IP, Host, @{Name = "Percentage"; Expression = {"{0:P4}" -f ($_.count / $packets.count)}}

		$global:stats = new-object psobject

		$stats | add-member noteproperty "TotalPackets" $packets.count
		$stats | add-member noteproperty "Elapsedtime" $elapsed
		$stats | add-member noteproperty "PacketsPerSec" $pps
		$stats | add-member noteproperty "Protocols" $protocols
		$stats | add-member noteproperty "Destinations" $destinations
		$stats | add-member noteproperty "DestinationPorts" $destinationport
		$stats | add-member noteproperty "Sources" $sources
		$stats | add-member noteproperty "SourcePorts" $sourceport

		write-host
		write-host " TotalPackets: " $stats.totalpackets
		write-host "  ElapsedTime: " $stats.elapsedtime
		write-host "PacketsPerSec: " $stats.packetspersec
		write-host
		write-host "More statistics can be accessed from the global `$stats variable." -fore cyan

	}
}