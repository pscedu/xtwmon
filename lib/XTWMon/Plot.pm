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

sub isfloat {
	return (defined $_[0] && $_[0] =~ /^-?(?:\d+\.?\d*|\d*\.\d+)([eE]-?\d+)?$/);
}

sub setview {
	my ($obj, $lx, $ly, $lz) = @_;
	$obj->{lx} = $lx if isfloat($lx);
	$obj->{ly} = $ly if isfloat($ly);
	$obj->{lz} = $lz if isfloat($lz);
}

sub setpos {
	my ($obj, $x, $y, $z) = @_;
	$obj->{x} = $x if isfloat($x);
	$obj->{y} = $y if isfloat($y);
	$obj->{z} = $z if isfloat($z);
}

sub setjob {
	my ($obj, $id) = @_;
	push @{ $obj->{jobs} }, $id if defined $id && $id =~ /^\d+$/;
}

1;
