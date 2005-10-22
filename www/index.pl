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
my $xtw = XTWMon->new($cgi->param("sid"));

my %p;
$p{t} = $cgi->param("t");
$p{p} = $cgi->param("p");
$p{z} = $cgi->param("z");
$p{hl} = $cgi->param("hl");
$p{vmode} = $cgi->param("vmode");
$p{smode} = $cgi->param("smode");
$p{sid} = $xtw->{sid};

my ($clicku, $clickv) = (-1, -1);
my $click = $cgi->param("click");
if ($click && $click =~ /^\?(\d+),(\d+)$/) {
	($clicku, $clickv) = ($1, $2);
}

$p{t} = 315 unless defined $p{t} && $p{t} =~ /^\d+$/;
$p{p} = 15 unless defined $p{p} && $p{p} =~ /^\d+$/;
$p{z} = 0 unless defined $p{z} && $p{z} =~ /^-?\d+$/;
delete $p{hl} unless defined $p{hl} && ($p{hl} eq "service" or
																				$p{hl} eq "free" or
																				$p{hl} eq "down");

my $tp = ($p{t} - 30) % 360;
my $tn = ($p{t} + 30) % 360;
my $pp = ($p{p} - 30) % 360;
my $pn = ($p{p} + 30) % 360;
my $zp = $p{z} - 20;
my $zn = $p{z} + 20;

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
		<script type="text/javascript" src="@{[$xtw->getpath(_GP_JOBJS, REL_WEBROOT)]}"></script>
	</head>
	<body>
		<map name="zoom">
			<area href="$url_view{forw}" shape="poly" alt="zoom in" coords="42,0, 43,0, 44,0, 45,0, 46,1, 47,1, 48,2, 49,2, 50,3, 51,4, 52,4, 53,5, 54,6, 55,6, 55,7, 54,7, 53,7, 52,7, 51,7, 50,7, 49,8, 49,9, 50,10, 50,11, 51,12, 51,13, 51,14, 52,15, 52,16, 52,17, 53,18, 53,19, 53,20, 54,21, 54,22, 54,23, 55,24, 55,25, 55,26, 56,27, 56,28, 56,29, 57,30, 57,31, 56,31, 55,31, 54,31, 53,31, 52,31, 51,31, 50,31, 49,31, 48,31, 47,31, 46,31, 45,31, 44,31, 43,31, 42,31, 41,31, 40,31, 39,31, 38,31, 37,31, 36,31, 35,31, 34,31, 33,31, 32,31, 31,31, 30,31, 30,30, 31,29, 31,28, 31,27, 32,26, 32,25, 32,24, 33,23, 33,22, 33,21, 34,20, 34,19, 34,18, 35,17, 35,16, 35,15, 36,14, 36,13, 36,12, 37,11, 37,10, 38,9, 38,8, 37,7, 36,7, 35,7, 34,7, 33,7, 32,7, 32,6, 33,6, 34,5, 35,4, 36,4, 37,3, 38,2, 39,2, 40,1, 41,1" />
			<area href="$url_view{back}" shape="poly" alt="zoom out" coords="26,42, 27,42, 28,42, 29,42, 30,42, 31,42, 32,42, 33,42, 34,42, 35,42, 36,42, 37,42, 38,42, 39,42, 40,42, 41,42, 42,42, 43,42, 44,42, 45,42, 46,42, 47,42, 48,42, 49,42, 50,42, 51,42, 52,42, 53,42, 54,42, 55,42, 56,42, 57,42, 58,42, 59,42, 60,42, 61,42, 61,43, 61,44, 62,45, 62,46, 62,47, 63,48, 63,49, 64,50, 64,51, 64,52, 65,53, 65,54, 66,55, 67,55, 68,55, 69,55, 70,55, 71,55, 72,55, 73,55, 74,55, 75,55, 76,55, 77,55, 78,55, 79,55, 80,55, 81,55, 82,55, 83,55, 84,55, 85,55, 86,55, 87,55, 87,56, 86,57, 85,58, 84,58, 83,59, 82,60, 81,60, 80,61, 79,62, 78,63, 77,63, 76,64, 75,65, 74,65, 73,66, 72,67, 71,68, 70,68, 69,69, 68,70, 67,70, 66,71, 65,72, 64,73, 63,73, 62,74, 61,75, 60,75, 59,76, 58,77, 57,78, 56,78, 55,79, 54,80, 53,80, 52,81, 51,82, 50,83, 49,83, 48,84, 47,85, 46,85, 45,86, 44,86, 43,86, 42,86, 41,85, 40,85, 39,84, 38,83, 37,83, 36,82, 35,81, 34,80, 33,80, 32,79, 31,78, 30,78, 29,77, 28,76, 27,75, 26,75, 25,74, 24,73, 23,73, 22,72, 21,71, 20,70, 19,70, 18,69, 17,68, 16,68, 15,67, 14,66, 13,65, 12,65, 11,64, 10,63, 9,63, 8,62, 7,61, 6,60, 5,60, 4,59, 3,58, 2,58, 1,57, 0,56, 0,55, 1,55, 2,55, 3,55, 4,55, 5,55, 6,55, 7,55, 8,55, 9,55, 10,55, 11,55, 12,55, 13,55, 14,55, 15,55, 16,55, 17,55, 18,55, 19,55, 20,55, 21,55, 22,54, 22,53, 23,52, 23,51, 23,50, 24,49, 24,48, 25,47, 25,46, 25,45, 26,44, 26,43" />
		</map>
		<map name="horz">
			<area href="$url_view{left}" shape="rect" alt="" coords="37,0,71,71" />
			<area href="$url_view{right}" shape="rect" alt="" coords="0,0,36,71" />
		</map>
		<map name="vert">
			<area href="$url_view{up}" shape="rect" alt="" coords="0,36,71,71" />
			<area href="$url_view{down}" shape="rect" alt="" coords="0,0,71,35" />
		</map>
EOF

my %p_extra = ();
$p_extra{clicku} = $clicku if $clicku ne -1;
$p_extra{clickv} = $clickv if $clickv ne -1;
my $plot_url = make_url("plot.pl", \%p, %p_extra);
my $click_url = make_url($uri, \%p);

print <<EOF;
		<table border="0" cellspacing="0" cellpadding="0" width="800">
			<tr>
				<td colspan="5">
				 <a href="${click_url}click="><img alt="[3d]" border="0" src="$plot_url" width="800"
				  ismap="ismap" height="450" style="border: 1px solid white" /></a></td>
			</tr>
			<tr valign="top">
				<td width="10%">
EOF

if (open FH, "< " . $xtw->getpath(_GP_LEGEND)) {
	print <FH>;
	close FH;
}

my $img_attr = qq{border="0" style="vertical-align: middle; padding: 3px"};

my %urls = (
	temp	=> make_url($uri, \%p, smode => "temp"),
	jobs	=> make_url($uri, \%p, smode => "jobs"),
	wired	=> make_url($uri, \%p, vmode => "wiredone"),
	phys	=> make_url($uri, \%p, vmode => "physical"),
);

my $s = <<EOF;
</td>
				<td width="60%" align="right">
					<div style="float: right">
						<a href="$urls{temp}"><img alt="[temp]"  src="img/temp.png" $img_attr /></a>
						<a href="$urls{jobs}"><img alt="[jobs]"  src="img/jobs.png" $img_attr /></a>
						<a href="$urls{wired}"><img alt="[wired]" src="img/wired.png" $img_attr /></a>
						<a href="$urls{phys}"><img alt="[phys]"  src="img/phys.png" $img_attr /></a><br />
						<!-- img alt="[pan]" usemap="#pan" src="img/pan.png" $img_attr / -->
						<img alt="[zoom]" usemap="#zoom" src="img/zoom.png" $img_attr />
						<img alt="[horz]" usemap="#horz" src="img/rot-horz.png" $img_attr />
						<img alt="[vert]" usemap="#vert" src="img/rot-vert.png" $img_attr />
					</div>
					<div id="pl_node" style="text-align: left; float: right; clear: none"></div>
				</td>
			</tr>
		</table>
		<hr />
		<div class="micro">Copyright &copy; 2005
		  <a href="http://www.psc.edu/">Pittsburgh Supercomputing Center</a></div>
		<script type='text/javascript'><!--
EOF

$s =~ s/(?<=>)\s+(?=<)//gs;
print $s;

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
