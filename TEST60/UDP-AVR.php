<?php
//foreach ( $_SERVER as $key => $waarde ) {
//	echo $key." = ".$waarde."<br>";
//};
	$remoteHost = "192.168.2.65";
	$remotePort = 987;
	$s = "Hello babe....";

	print "[UDP:SOCKET $remoteHost:$remotePort]<BR>";
	$socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
	if (!$socket) die("No socket created");
	print ".create<BR>";
	socket_bind($socket, "0.0.0.0", $remotePort);
	print ".bind<BR>";
	socket_connect($socket, $remoteHost, $remotePort); 
	print ".connect<BR>";
	socket_write($socket, $s, strlen($s));
	print ".write $s<BR>";
	socket_shutdown($socket, 2); //for reading and writing
	print ".shutdown<BR>";
	socket_close($socket);
	print ".close<BR>";
?>
