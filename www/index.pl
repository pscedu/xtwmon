#!/usr/bin/perl -W
# $Id$

use lib qw(../lib);
use XTWMon;
use strict;
use warnings;

use constant MAX_X => 11;
use constant MAX_Y => 12;
use constant MAX_Z => 16;

my $r = shift;
$r->content_type('text/html');
my $cgi = CGI->new();

my %p;
$p{t} = $cgi->param("t");
$p{p} = $cgi->param("p");

$p{t} = 0 unless defined $p{t} && $p{t} =~ /^\d+$/;
$p{p} = 0 unless defined $p{p} && $p{p} =~ /^\d+$/;

my $tp = ($p{t} - 20) % 360;
my $tn = ($p{t} + 20) % 360;
my $pp = ($p{p} - 20) % 360;
my $pn = ($p{p} + 20) % 360;

# Bounds.
$pp = 270 if $p{p} >= 270 && $pp < 270;
$pn =  90 if $p{p} <=  90 && $pn >  90;

$p{job} = $cgi->param('job');
$p{job} = 0 unless $p{job} && $p{job} =~ /^\d+$/;

# It is imperative that all variables affecting the URL
# be set before make_url() is called.

my $uri = $r->uri;

my %url_view = (
	left	=> make_url($uri, \%p, t => $tn),
	right	=> make_url($uri, \%p, t => $tp),
	up	  => make_url($uri, \%p, p => $pn),
	down  => make_url($uri, \%p, p => $pp),
);

$r->print(<<EOF);
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN">

<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Wired XT3 Monitor</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
		<link rel="stylesheet" type="text/css" href="main.css" media="screen" />
		<script type="text/javascript" src="main.js"></script>
		<script type="text/javascript" src="latest/jobs.js"></script>
		<script type='text/javascript'>
			preload('@{[ make_url('plot.pl', \%p, t => $tn) ]}')
			preload('@{[ make_url('plot.pl', \%p, t => $tp) ]}')
			preload('@{[ make_url('plot.pl', \%p, p => $pn) ]}')
			preload('@{[ make_url('plot.pl', \%p, p => $pp) ]}')
		</script>
	</head>
	<body>
		<map name="view" id="view">
			<area href="$url_view{up}"   shape="poly" alt="revolve up (theta++)" coords="73,23, 74,23, 75,23, 76,23, 77,23, 78,23, 79,23, 80,23, 81,23, 82,24, 83,25, 82,26, 82,27, 81,28, 81,29, 80,30, 80,31, 79,32, 79,33, 78,34, 78,35, 77,36, 77,37, 76,38, 75,39, 74,38, 73,37, 72,37, 71,38, 70,39, 70,40, 69,41, 69,42, 69,43, 68,44, 68,45, 68,46, 67,47, 66,48, 65,48, 64,48, 63,48, 62,48, 61,48, 60,48, 59,48, 58,47, 57,46, 57,45, 57,44, 58,43, 58,42, 58,41, 58,40, 59,39, 59,38, 60,37, 60,36, 61,35, 61,34, 62,33, 62,32, 63,31, 64,30, 64,29, 63,28, 62,27, 62,26, 63,25, 64,24, 65,24, 66,24, 67,24, 68,24, 69,24, 70,24, 71,24, 72,24" />
			<area href="$url_view{down}"  shape="poly" alt="revolve down (theta--)" coords="59,82, 60,82, 61,82, 62,82, 63,82, 64,82, 65,82, 66,82, 67,83, 68,84, 68,85, 68,86, 69,87, 69,88, 69,89, 70,90, 70,91, 71,92, 72,93, 73,93, 74,92, 75,91, 76,92, 77,93, 77,94, 78,95, 78,96, 79,97, 79,98, 80,99, 80,100, 81,101, 81,102, 82,103, 82,104, 83,105, 82,106, 81,107, 80,107, 79,107, 78,107, 77,107, 76,107, 75,107, 74,107, 73,107, 72,106, 71,106, 70,106, 69,106, 68,106, 67,106, 66,106, 65,106, 64,106, 63,105, 62,104, 62,103, 63,102, 64,101, 64,100, 63,99, 62,98, 62,97, 61,96, 61,95, 60,94, 60,93, 59,92, 59,91, 58,90, 58,89, 58,88, 58,87, 57,86, 57,85, 57,84, 58,83" />
			<area href="$url_view{right}" shape="poly" alt="revolve right (theta--)" coords="104,46, 105,47, 106,48, 106,49, 106,50, 106,51, 106,52, 106,53, 106,54, 106,55, 106,56, 105,57, 105,58, 105,59, 105,60, 105,61, 105,62, 105,63, 105,64, 105,65, 104,66, 103,67, 102,67, 101,66, 100,65, 99,65, 98,66, 97,67, 96,67, 95,68, 94,68, 93,69, 92,69, 91,70, 90,70, 89,71, 88,71, 87,71, 86,71, 85,72, 84,72, 83,72, 82,71, 81,70, 81,69, 81,68, 81,67, 81,66, 81,65, 81,64, 81,63, 82,62, 83,61, 84,61, 85,61, 86,60, 87,60, 88,60, 89,59, 90,59, 91,58, 92,57, 92,56, 91,55, 90,54, 91,53, 92,52, 93,52, 94,51, 95,51, 96,50, 97,50, 98,49, 99,49, 100,48, 101,48, 102,47, 103,47" />
			<area href="$url_view{left}"  shape="poly" alt="revolve left (theta++)" coords="23,46, 24,47, 25,47, 26,48, 27,48, 28,49, 29,49, 30,50, 31,50, 32,51, 33,51, 34,52, 35,52, 36,53, 37,54, 36,55, 35,56, 35,57, 36,58, 37,59, 38,59, 39,60, 40,60, 41,60, 42,61, 43,61, 44,61, 45,62, 46,63, 46,64, 46,65, 46,66, 46,67, 46,68, 46,69, 46,70, 45,71, 44,72, 43,72, 42,72, 41,71, 40,71, 39,71, 38,71, 37,70, 36,70, 35,69, 34,69, 33,68, 32,68, 31,67, 30,67, 29,66, 28,65, 27,65, 26,66, 25,67, 24,67, 23,66, 22,65, 22,64, 22,63, 22,62, 22,61, 22,60, 22,59, 22,58, 22,57, 21,56, 21,55, 21,54, 21,53, 21,52, 21,51, 21,50, 21,49, 21,48, 22,47" />
		</map>
EOF

my $plot_url = make_url("plot.pl", \%p);

print <<EOF;
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td colspan="5">
				 <img alt="[3d]" border="0" src="$plot_url" width="1000"
				  height="600" style="border: 1px solid white" /></td>
			</tr>
			<tr valign="top">
				<td width="10%">
EOF

if (open FH, "< " . _PATH_LEGEND) {
	print <FH>;
	close FN;
}

print <<EOF;
</td>
				<td width="60%" align="right">
					<img alt="[view]" border="0" usemap="#view" src="img/sphere.png"
					 align="right" style="padding: 1px; padding-left: 5px" />
					<div id="pl_node" style="text-align: right"></div></td>
			</tr>
		</table>
		<hr />
		<div class="micro">Copyright &copy; 2005
		  <a href="http://www.psc.edu/">Pittsburgh Supercomputing Center</a></div>
		<script type='text/javascript'><!--
EOF

print "seljob($p{job})\n" if $p{job};

print <<EOF;
		// -->
		</script>
	</body>
</html>
EOF

sub make_url {
	my ($page, $rp, %params) = @_;
	my $url = $page . "?";
	foreach (keys %$rp) {
		if (exists $params{$_}) {
			$url .= "$_=$params{$_}&amp;";
		} elsif (exists $rp->{$_} && $rp->{$_}) {
			$url .= "$_=$rp->{$_}&amp;";
		}
	}
	return ($url);
}

# vim: set ts=2:
