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
$p{z} = $cgi->param("z");

my ($clicku, $clickv) = (-1, -1);
my $click = $cgi->param("click");
if ($click && $click =~ /^\?(\d+),(\d+)$/) {
	($clicku, $clickv) = ($1, $2);
}

$p{t} = 0 unless defined $p{t} && $p{t} =~ /^\d+$/;
$p{p} = 0 unless defined $p{p} && $p{p} =~ /^\d+$/;
$p{z} = 0 unless defined $p{z} && $p{z} =~ /^-?\d+$/;

my $tp = ($p{t} - 30) % 360;
my $tn = ($p{t} + 30) % 360;
my $pp = ($p{p} - 30) % 360;
my $pn = ($p{p} + 30) % 360;
my $zp = $p{z} - 10;
my $zn = $p{z} + 10;

# Bounds.
$pp = 270 if $p{p} >= 270 && $pp < 270;
$pn =  90 if $p{p} <=  90 && $pn >  90;

$p{z} = ZOOM_MAX if $p{z} > ZOOM_MAX;
$p{z} = ZOOM_MIN if $p{z} < ZOOM_MIN;

$zp = ZOOM_MAX if $zp > ZOOM_MAX;
$zp = ZOOM_MIN if $zp < ZOOM_MIN;

$zn = ZOOM_MAX if $zn > ZOOM_MAX;
$zn = ZOOM_MIN if $zn < ZOOM_MIN;

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
	forw  => make_url($uri, \%p, z => $zn),
	back  => make_url($uri, \%p, z => $zp),
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
	</head>
	<body>
		<map name="view" id="view">
			<area href="$url_view{up}"    shape="poly" alt="revolve up (theta++)" coords="73,23, 74,23, 75,23, 76,23, 77,23, 78,23, 79,23, 80,23, 81,23, 82,24, 83,25, 82,26, 82,27, 81,28, 81,29, 80,30, 80,31, 79,32, 79,33, 78,34, 78,35, 77,36, 77,37, 76,38, 75,39, 74,38, 73,37, 72,37, 71,38, 70,39, 70,40, 69,41, 69,42, 69,43, 68,44, 68,45, 68,46, 67,47, 66,48, 65,48, 64,48, 63,48, 62,48, 61,48, 60,48, 59,48, 58,47, 57,46, 57,45, 57,44, 58,43, 58,42, 58,41, 58,40, 59,39, 59,38, 60,37, 60,36, 61,35, 61,34, 62,33, 62,32, 63,31, 64,30, 64,29, 63,28, 62,27, 62,26, 63,25, 64,24, 65,24, 66,24, 67,24, 68,24, 69,24, 70,24, 71,24, 72,24" />
			<area href="$url_view{down}"  shape="poly" alt="revolve down (theta--)" coords="59,82, 60,82, 61,82, 62,82, 63,82, 64,82, 65,82, 66,82, 67,83, 68,84, 68,85, 68,86, 69,87, 69,88, 69,89, 70,90, 70,91, 71,92, 72,93, 73,93, 74,92, 75,91, 76,92, 77,93, 77,94, 78,95, 78,96, 79,97, 79,98, 80,99, 80,100, 81,101, 81,102, 82,103, 82,104, 83,105, 82,106, 81,107, 80,107, 79,107, 78,107, 77,107, 76,107, 75,107, 74,107, 73,107, 72,106, 71,106, 70,106, 69,106, 68,106, 67,106, 66,106, 65,106, 64,106, 63,105, 62,104, 62,103, 63,102, 64,101, 64,100, 63,99, 62,98, 62,97, 61,96, 61,95, 60,94, 60,93, 59,92, 59,91, 58,90, 58,89, 58,88, 58,87, 57,86, 57,85, 57,84, 58,83" />
			<area href="$url_view{right}" shape="poly" alt="revolve right (theta--)" coords="104,46, 105,47, 106,48, 106,49, 106,50, 106,51, 106,52, 106,53, 106,54, 106,55, 106,56, 105,57, 105,58, 105,59, 105,60, 105,61, 105,62, 105,63, 105,64, 105,65, 104,66, 103,67, 102,67, 101,66, 100,65, 99,65, 98,66, 97,67, 96,67, 95,68, 94,68, 93,69, 92,69, 91,70, 90,70, 89,71, 88,71, 87,71, 86,71, 85,72, 84,72, 83,72, 82,71, 81,70, 81,69, 81,68, 81,67, 81,66, 81,65, 81,64, 81,63, 82,62, 83,61, 84,61, 85,61, 86,60, 87,60, 88,60, 89,59, 90,59, 91,58, 92,57, 92,56, 91,55, 90,54, 91,53, 92,52, 93,52, 94,51, 95,51, 96,50, 97,50, 98,49, 99,49, 100,48, 101,48, 102,47, 103,47" />
			<area href="$url_view{left}"  shape="poly" alt="revolve left (theta++)" coords="23,46, 24,47, 25,47, 26,48, 27,48, 28,49, 29,49, 30,50, 31,50, 32,51, 33,51, 34,52, 35,52, 36,53, 37,54, 36,55, 35,56, 35,57, 36,58, 37,59, 38,59, 39,60, 40,60, 41,60, 42,61, 43,61, 44,61, 45,62, 46,63, 46,64, 46,65, 46,66, 46,67, 46,68, 46,69, 46,70, 45,71, 44,72, 43,72, 42,72, 41,71, 40,71, 39,71, 38,71, 37,70, 36,70, 35,69, 34,69, 33,68, 32,68, 31,67, 30,67, 29,66, 28,65, 27,65, 26,66, 25,67, 24,67, 23,66, 22,65, 22,64, 22,63, 22,62, 22,61, 22,60, 22,59, 22,58, 22,57, 21,56, 21,55, 21,54, 21,53, 21,52, 21,51, 21,50, 21,49, 21,48, 22,47" />
		</map>
		<map name="zoom">
			<area href="$url_view{forw}" shape="poly" alt="zoom in" coords="42,0, 43,0, 44,0, 45,0, 46,1, 47,1, 48,2, 49,2, 50,3, 51,4, 52,4, 53,5, 54,6, 55,6, 55,7, 54,7, 53,7, 52,7, 51,7, 50,7, 49,8, 49,9, 50,10, 50,11, 51,12, 51,13, 51,14, 52,15, 52,16, 52,17, 53,18, 53,19, 53,20, 54,21, 54,22, 54,23, 55,24, 55,25, 55,26, 56,27, 56,28, 56,29, 57,30, 57,31, 56,31, 55,31, 54,31, 53,31, 52,31, 51,31, 50,31, 49,31, 48,31, 47,31, 46,31, 45,31, 44,31, 43,31, 42,31, 41,31, 40,31, 39,31, 38,31, 37,31, 36,31, 35,31, 34,31, 33,31, 32,31, 31,31, 30,31, 30,30, 31,29, 31,28, 31,27, 32,26, 32,25, 32,24, 33,23, 33,22, 33,21, 34,20, 34,19, 34,18, 35,17, 35,16, 35,15, 36,14, 36,13, 36,12, 37,11, 37,10, 38,9, 38,8, 37,7, 36,7, 35,7, 34,7, 33,7, 32,7, 32,6, 33,6, 34,5, 35,4, 36,4, 37,3, 38,2, 39,2, 40,1, 41,1" />
			<area href="$url_view{back}" shape="poly" alt="zoom out" coords="26,42, 27,42, 28,42, 29,42, 30,42, 31,42, 32,42, 33,42, 34,42, 35,42, 36,42, 37,42, 38,42, 39,42, 40,42, 41,42, 42,42, 43,42, 44,42, 45,42, 46,42, 47,42, 48,42, 49,42, 50,42, 51,42, 52,42, 53,42, 54,42, 55,42, 56,42, 57,42, 58,42, 59,42, 60,42, 61,42, 61,43, 61,44, 62,45, 62,46, 62,47, 63,48, 63,49, 64,50, 64,51, 64,52, 65,53, 65,54, 66,55, 67,55, 68,55, 69,55, 70,55, 71,55, 72,55, 73,55, 74,55, 75,55, 76,55, 77,55, 78,55, 79,55, 80,55, 81,55, 82,55, 83,55, 84,55, 85,55, 86,55, 87,55, 87,56, 86,57, 85,58, 84,58, 83,59, 82,60, 81,60, 80,61, 79,62, 78,63, 77,63, 76,64, 75,65, 74,65, 73,66, 72,67, 71,68, 70,68, 69,69, 68,70, 67,70, 66,71, 65,72, 64,73, 63,73, 62,74, 61,75, 60,75, 59,76, 58,77, 57,78, 56,78, 55,79, 54,80, 53,80, 52,81, 51,82, 50,83, 49,83, 48,84, 47,85, 46,85, 45,86, 44,86, 43,86, 42,86, 41,85, 40,85, 39,84, 38,83, 37,83, 36,82, 35,81, 34,80, 33,80, 32,79, 31,78, 30,78, 29,77, 28,76, 27,75, 26,75, 25,74, 24,73, 23,73, 22,72, 21,71, 20,70, 19,70, 18,69, 17,68, 16,68, 15,67, 14,66, 13,65, 12,65, 11,64, 10,63, 9,63, 8,62, 7,61, 6,60, 5,60, 4,59, 3,58, 2,58, 1,57, 0,56, 0,55, 1,55, 2,55, 3,55, 4,55, 5,55, 6,55, 7,55, 8,55, 9,55, 10,55, 11,55, 12,55, 13,55, 14,55, 15,55, 16,55, 17,55, 18,55, 19,55, 20,55, 21,55, 22,54, 22,53, 23,52, 23,51, 23,50, 24,49, 24,48, 25,47, 25,46, 25,45, 26,44, 26,43" />
		</map>
EOF

my %p_extra = ();
$p_extra{clicku} = $clicku if $clicku ne -1;
$p_extra{clickv} = $clickv if $clickv ne -1;
my $plot_url = make_url("plot.pl", \%p, %p_extra);
my $click_url = make_url($uri, \%p);

print <<EOF;
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td colspan="5">
				 <a href="${click_url}click="><img alt="[3d]" border="0" src="$plot_url" width="800"
				  ismap="ismap" height="450" style="border: 1px solid white" /></a></td>
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
					<div style="float: right">
						<img alt="[zoom]" border="0" usemap="#zoom" src="img/zoom.png"
						 style="vertical-align: middle" style="padding: 1px; padding-left: 5px"
						 /><img alt="[view]" border="0" usemap="#view" src="img/sphere.png"
						 style="vertical-align: middle; padding: 1px; padding-left: 5px" /></div>
					<div id="pl_node" style="text-align: left; float: right"></div>
					</td>
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
			delete $params{$_};
		} elsif (exists $rp->{$_} && $rp->{$_}) {
			$url .= "$_=$rp->{$_}&amp;";
		}
	}
	foreach (keys %params) {
		$url .= "$_=$params{$_}&amp;";
	}
	return ($url);
}

# vim: set ts=2:
