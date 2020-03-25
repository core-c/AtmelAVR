#!/usr/local/bin/perl -w
use strict;
use Socket;

my $paddr;

sub udpinit();
sub gui();
sub udpsend($);

udpinit();
while(1) {
	gui();
}
exit(0);

sub udpinit() {
	my $proto = getprotobyname('udp');
	socket(SOCKET, PF_INET, SOCK_DGRAM, $proto);
	my $remote = "192.168.2.65";
	my $port = 987;
	my $iaddr = gethostbyname($remote);
	$paddr = sockaddr_in($port, $iaddr);
}

sub gui() {
	$| = 1;
	print "enter a 4-line message (20 chars/line max):\n";
	my $pad = ' ' x 20;
	my @lines = ();
	my $line;
	print " >....................<\n";
	while (@lines < 4) {
		print scalar(@lines)+1, " >";
		$line = <STDIN>;
		chomp($line);
		$line .= $pad;
		$line = substr($line, 0, 20);
		push(@lines, $line);
	}
	print "\n\n Your message will look like this:\n";
	print " |----------------------|\n";
	foreach my $line (@lines) {
		print " | ", $line, " |\n";
	}
	print " |----------------------|\n";
	my $message = join('', @lines);
	print "\nSending...\n";
	my $bytecount = udpsend($message);
	print $bytecount, " bytes sent.\n\n";
}

sub udpsend($) {
	my $message = $_[0];
	my $bytecount = send(SOCKET, $message, 0, $paddr);
	return($bytecount);
}
