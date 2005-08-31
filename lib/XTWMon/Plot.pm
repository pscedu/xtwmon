#!/usr/bin/perl
# $Id$

package XTWMon::Plot;

use lib qw(..);
use XTWMon;
use CGI;
use IO::Socket;
use strict;
use warnings;

use constant XT3D_HOST => "localhost";
use constant XT3D_PORT => 24242;

use constant DEF_X  => -55.00;
use constant DEF_Y  =>  38.00;
use constant DEF_Z  =>  70.00;
use constant DEF_LX =>   0.86;
use constant DEF_LY =>  -0.24;
use constant DEF_LZ =>  -0.45;

use constant WIDTH => 500;
use constant HEIGHT => 300;

sub new {
	my ($class) = @_;
	my $pkg = ref($class) || $class;
	return bless {
		x	=> DEF_X,
		y	=> DEF_Y,
		z	=> DEF_Z,
		lx	=> DEF_LX,
		ly	=> DEF_LY,
		lz	=> DEF_LZ,
		jobs	=> []
	}, $pkg;
}

sub print {
	my ($obj) = @_;
	my $s = IO::Socket::INET->new(
		PeerAddr => XT3D_HOST,
		PeerPort => XT3D_PORT,
		Proto => 'tcp') or $obj->err("socket");
	my ($sw, $sh) = (WIDTH, HEIGHT);
	print $s <<EOF;
x: $obj->{x}
y: $obj->{y}
z: $obj->{z}
lx: $obj->{lx}
ly: $obj->{ly}
lz: $obj->{lz}
sw: $sw
sh: $sh
vmode: wiredone
EOF
	print <$s>;
	close $s;
}

sub err {
	shift;
	(my $progname = $0) =~ s!.*/!!;
	warn "$progname: ", @_, ": $!\n";
	exit 1;
}

sub setview {
	my ($obj, $lx, $ly, $lz) = @_;
	$obj->{lx} = $lx if defined $lx && $lx =~ /^\d+$/;
	$obj->{ly} = $ly if defined $ly && $ly =~ /^\d+$/;
	$obj->{lz} = $lz if defined $lz && $lz =~ /^\d+$/;
}

sub setpos {
	my ($obj, $x, $y, $z) = @_;
	$obj->{x} = $x if defined $x && $x =~ /^\d+$/;
	$obj->{y} = $y if defined $y && $y =~ /^\d+$/;
	$obj->{z} = $z if defined $z && $z =~ /^\d+$/;
}

sub setjob {
	my ($obj, $id) = @_;
	push @{ $obj->{jobs} }, $id if defined $id && $id =~ /^\d+$/;
}

1;
