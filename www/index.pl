#!/usr/bin/perl -W
# $Id$

use strict;
use warnings;

use constant MAX_X => 11;
use constant MAX_Y => 12;
use constant MAX_Z => 16;

my $r = shift;
$r->content_type('text/html');
my $cgi = CGI->new();

my $x_pos = $cgi->param("xpos") || 0;
my $y_pos = $cgi->param("ypos") || 0;
my $z_pos = $cgi->param("zpos") || 0;

$x_pos = 0 if $x_pos !~ /^\d+$/ || $x_pos < 0 || $x_pos >= MAX_X;
$y_pos = 0 if $y_pos !~ /^\d+$/ || $y_pos < 0 || $y_pos >= MAX_Y;
$z_pos = 0 if $z_pos !~ /^\d+$/ || $z_pos < 0 || $z_pos >= MAX_Z;

my $uri = $r->uri;

my ($x_posn, $x_posp, $y_posn, $y_posp, $z_posn, $z_posp);
$x_posn = ($x_pos + 1) % MAX_X;
$y_posn = ($y_pos + 1) % MAX_Y;
$z_posn = ($z_pos + 1) % MAX_Z;

$x_posp = ($x_pos - 1) % MAX_X;
$y_posp = ($y_pos - 1) % MAX_Y;
$z_posp = ($z_pos - 1) % MAX_Z;

my %url_dir = (
	"forw"	=> "$uri?xpos=$x_posn&amp;ypos=$y_pos&amp;zpos=$z_pos",
	"back"	=> "$uri?xpos=$x_posp&amp;ypos=$y_pos&amp;zpos=$z_pos",
	"left"	=> "$uri?xpos=$x_pos&amp;ypos=$y_pos&amp;zpos=$z_posp",
	"right"	=> "$uri?xpos=$x_pos&amp;ypos=$y_pos&amp;zpos=$z_posn",
	"up"	=> "$uri?xpos=$x_pos&amp;ypos=$y_posn&amp;zpos=$z_pos",
	"down"	=> "$uri?xpos=$x_pos&amp;ypos=$y_posp&amp;zpos=$z_pos"
);

$r->print(<<EOF);
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">

<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Wired XT3 Monitor</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
		<link rel="stylesheet" type="text/css" href="main.css" media="screen" />
		<script type="text/javascript" src="main.js"></script>
	</head>
	<body>
		<map name="nav" id="nav">
			<area href="$url_dir{forw}"  shape="poly" alt="forward (x++)" coords="113,2, 114,2, 115,2, 116,2, 116,2, 117,3, 118,4, 119,5, 118,5, 118,6, 118,7, 117,8, 117,8, 117,9, 116,10, 116,11, 116,11, 116,12, 116,13, 116,14, 116,14, 115,15, 115,16, 115,17, 114,17, 114,18, 114,19, 113,20, 113,20, 112,21, 111,22, 110,21, 110,20, 109,20, 108,19, 107,19, 107,20, 106,20, 105,21, 104,22, 104,23, 103,23, 102,24, 101,25, 101,26, 100,26, 99,27, 98,28, 98,29, 97,29, 96,30, 95,29, 95,29, 94,28, 93,27, 92,26, 92,26, 91,25, 91,24, 91,23, 92,23, 92,22, 93,21, 94,20, 95,20, 95,19, 96,18, 97,17, 98,17, 98,16, 99,15, 100,14, 101,14, 101,13, 101,12, 101,11, 100,11, 99,10, 98,9, 98,8, 98,8, 98,7, 99,6, 100,5, 101,5, 101,5, 102,5, 103,5, 104,5, 104,5, 105,5, 106,5, 107,4, 107,4, 108,4, 109,4, 110,3, 110,3, 111,3, 112,3, 113,3" />
			<area href="$url_dir{back}"  shape="poly" alt="back (x--)" coords="22,92, 23,92, 23,92, 24,93, 25,94, 26,95, 26,95, 26,96, 26,97, 26,98, 26,98, 26,99, 25,100, 24,101, 23,101, 23,102, 22,103, 21,104, 20,104, 20,105, 19,106, 18,107, 17,107, 17,108, 17,109, 17,110, 18,110, 19,111, 20,112, 20,113, 20,113, 20,114, 19,114, 18,114, 17,114, 17,114, 16,115, 15,115, 14,115, 14,115, 13,116, 12,116, 11,116, 11,116, 10,116, 9,116, 8,116, 8,116, 7,116, 6,117, 5,117, 5,117, 4,117, 3,117, 2,117, 2,117, 2,116, 2,116, 2,115, 2,114, 2,113, 3,113, 3,112, 3,111, 4,110, 4,110, 4,109, 4,108, 5,107, 5,107, 5,106, 5,105, 5,104, 5,104, 6,103, 6,102, 6,101, 7,101, 8,101, 8,101, 9,101, 10,102, 11,103, 11,103, 12,102, 13,101, 14,101, 14,100, 15,99, 16,98, 17,98, 17,97, 18,96, 19,95, 20,95, 20,94, 21,93" />
			<area href="$url_dir{up}"    shape="poly" alt="up (y++)" coords="60,9, 61,9, 62,10, 62,11, 63,11, 64,12, 64,13, 65,14, 65,14, 65,15, 65,16, 65,17, 65,17, 66,18, 66,19, 67,20, 67,20, 67,21, 68,22, 68,23, 68,23, 68,24, 68,25, 68,26, 67,26, 66,27, 65,27, 65,28, 65,29, 65,29, 65,30, 65,31, 65,32, 65,32, 65,33, 65,34, 65,35, 65,35, 64,36, 63,37, 62,38, 62,38, 61,38, 60,38, 59,38, 59,38, 58,37, 57,36, 56,35, 56,35, 56,34, 56,33, 56,32, 56,32, 56,31, 56,30, 56,29, 56,29, 56,28, 56,27, 55,27, 54,27, 53,26, 53,26, 52,25, 52,24, 52,23, 53,23, 53,22, 53,21, 53,20, 54,20, 54,19, 55,18, 55,17, 55,17, 56,16, 56,15, 56,14, 56,14, 57,13, 57,12, 58,11, 59,11, 59,10" />
			<area href="$url_dir{down}"  shape="poly" alt="down (y--)" coords="58,88, 59,88, 59,88, 60,88, 61,88, 62,88, 62,89, 63,89, 64,90, 64,91, 64,92, 64,92, 64,93, 64,94, 64,95, 64,95, 64,96, 64,97, 64,98, 65,98, 65,98, 66,98, 67,99, 68,100, 68,101, 68,101, 68,102, 68,103, 67,104, 67,104, 67,105, 66,106, 66,107, 65,107, 65,108, 65,109, 65,110, 65,110, 64,111, 64,112, 63,113, 63,113, 62,114, 62,115, 61,116, 60,116, 59,116, 59,116, 58,115, 57,114, 56,113, 56,113, 56,112, 56,111, 56,110, 55,110, 55,109, 55,108, 54,107, 54,107, 53,106, 53,105, 53,104, 53,104, 53,103, 52,102, 52,101, 52,101, 53,100, 53,99, 54,98, 55,98, 56,98, 56,97, 56,96, 56,95, 56,95, 56,94, 56,93, 56,92, 56,92, 56,91, 56,90, 56,89, 57,89" />
			<area href="$url_dir{right}" shape="poly" alt="right (z++)" coords="92,53, 93,53, 94,53, 95,53, 95,54, 96,54, 97,54, 98,55, 98,55, 99,56, 100,56, 101,56, 101,56, 102,56, 103,57, 104,57, 104,58, 105,58, 106,59, 107,59, 107,60, 108,61, 108,62, 107,62, 107,63, 106,64, 105,65, 104,65, 104,65, 103,65, 102,65, 101,66, 101,66, 100,66, 99,67, 98,67, 98,68, 97,68, 96,68, 95,68, 95,68, 94,69, 93,69, 92,69, 92,68, 91,68, 90,67, 90,66, 89,65, 89,65, 88,65, 87,65, 86,65, 86,65, 85,65, 84,65, 83,65, 83,65, 82,65, 81,65, 80,64, 80,63, 80,62, 80,62, 80,61, 80,60, 80,59, 80,59, 81,58, 82,57, 83,57, 83,57, 84,57, 85,57, 86,57, 86,57, 87,57, 88,57, 89,57, 89,57, 90,56, 90,56, 90,55, 91,54, 92,53" />
			<area href="$url_dir{left}"  shape="poly" alt="left (z--)" coords="17,55, 17,55, 18,55, 19,56, 20,56, 20,57, 20,58, 21,59, 22,59, 23,59, 23,59, 24,59, 25,59, 26,59, 26,59, 27,59, 28,59, 29,59, 29,59, 30,60, 31,61, 31,62, 31,62, 31,63, 31,64, 31,65, 30,65, 29,66, 29,67, 28,67, 27,67, 26,67, 26,67, 25,67, 24,67, 23,67, 23,67, 22,67, 21,67, 20,68, 20,68, 20,69, 20,70, 19,71, 18,71, 17,71, 17,71, 16,71, 15,70, 14,70, 14,70, 13,69, 12,69, 11,68, 11,68, 10,68, 9,68, 8,68, 8,67, 7,67, 6,66, 5,66, 5,65, 4,65, 3,64, 2,63, 2,62, 3,62, 4,61, 5,60, 5,59, 6,59, 7,59, 8,59, 8,59, 9,58, 10,58, 11,58, 11,57, 12,57, 13,56, 14,56, 14,56, 15,56, 16,56" />
		</map>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr valign="middle">
				<td><img alt="[xz]" border="0" usemap="latest/map.html#xz"
					 src="latest/y$y_pos.png" /></td>
				<td width="10"></td>
				<td><img alt="[3d]" border="0" src="plot.pl" /></td>
			</tr>
			<tr>
				<td><img alt="[xy]" border="0" usemap="map.html#xy"
					 src="latest/z$z_pos.png" /></td>
				<td></td>
				<td><img alt="[yz]" border="0" usemap="map.html#yz"
					 src="latest/x$x_pos.png" /></td>
			</tr>
			<tr>
				<td colspan="3" align="center">
					<img alt="[nav]" border="0" usemap="#nav" src="nav.png" /></td>
			</tr>
		</table>
		<div class="micro">Copyright &copy; 2005
		  <a href="http://www.psc.edu/">Pittsburgh Supercomputing Center</a></div>
	</body>
</html>
EOF

# vim: set ts=2:
