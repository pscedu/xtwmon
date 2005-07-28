#!/usr/bin/perl -W
# $Id$

use WASP;
use OOF;

use strict;
use warnings;;

use constant MAX_X => 11;
use constant MAX_Y => 12;
use constant MAX_Z => 16;

my $r = shift;
my $wasp = WASP->new();
my $oof = OOF->new(wasp=>$wasp, filter=>"XHTML");
my $cgi = CGI->new();

my $x_pos = $cgi->param("xpos") || 0;
my $y_pos = $cgi->param("ypos") || 0;
my $z_pos = $cgi->param("zpos") || 0;

$x_pos = 0 if $x_pos !~ /^\d+$/ || $x_pos < 0 || $x_pos >= MAX_X;
$y_pos = 0 if $y_pos !~ /^\d+$/ || $y_pos < 0 || $y_pos >= MAX_Y;
$z_pos = 0 if $z_pos !~ /^\d+$/ || $z_pos < 0 || $z_pos >= MAX_Z;

$r->print(<<EOF);
<!DOCTYPE html PUBLIC "-//W3C//XHTML 1.0 Transitional//EN">

<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Wired XT3 Monitor</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
		<style type="text/css">
			body {
				font-family: Tahoma, sans-serif;
			}

			.micro {
				font-size: 11px;
				color: #002233;
			}
		</style>
		<map name="xz">
		</map>
		<map name="xy">
		</map>
		<map name="yz">
		</map>
	</head>
	<body>
		<div>
			<img alt="[xz]" border="0" width=600 height=400 usemap="#xz" src="latest/y$y_pos.png" align="left" />
			<img alt="[3d]" border="0" width=600 height=400 usemap="#3d" src="latest/3d.png" />
			</div>
		<div>
			<img alt="[xy]" border="0" width=600 height=400 usemap="#xy" src="latest/z$z_pos.png" align="left" />
			<img alt="[yz]" border="0" width=600 height=400 usemap="#yz" src="latest/x$x_pos.png" /></div>
		<div></div>
		<div class="micro">Copyright &copy; 2005
		  <a href="http://www.psc.edu/">Pittsburgh Supercomputing Center</a></div>
	</body>
</html>
EOF
