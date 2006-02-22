#!/usr/bin/perl -W
# $Id$

use lib qw(../lib);
use XTWMon;
use strict;
use warnings;

my $r = shift;
$r->content_type('text/html');
my $cgi = CGI->new();
my $req_sid = $cgi->param("sid");
my $xtw = XTWMon->new($req_sid);

my %p;
$p{t} = $cgi->param("t");
$p{p} = $cgi->param("p");
$p{z} = $cgi->param("z");
$p{hl} = $cgi->param("hl");
$p{vmode} = $cgi->param("vmode");
$p{smode} = $cgi->param("smode");
$p{sid} = $xtw->{sid};

unless (defined $req_sid and $req_sid eq $p{sid}) {
	print $cgi->redirect(make_url($r->uri, \%p));
	exit;
}

my ($clicku, $clickv) = (-1, -1);
my $click = $cgi->param("click");
if ($click && $click =~ /^\?(\d+),(\d+)$/) {
	($clicku, $clickv) = ($1, $2);
}

$p{t} = 315 unless defined $p{t} && $p{t} =~ /^\d+$/;
$p{p} = 15 unless defined $p{p} && $p{p} =~ /^\d+$/;
$p{z} = 0 unless defined $p{z} && $p{z} =~ /^-?\d+$/;
delete $p{hl} unless hl_valid($p{hl});
$p{vmode} = "wiredone" unless vmode_valid($p{vmode});
$p{smode} = "jobs" unless smode_valid($p{smode});

my $tp = ($p{t} - 30) % 360;
my $tn = ($p{t} + 30) % 360;
my $pp = ($p{p} - 20) % 360;
my $pn = ($p{p} + 20) % 360;
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
		<script type="text/javascript">
			<!--
				var defparams = []
				defparams['sid'] = '$p{sid}'
			// -->
		</script>
		<script type="text/javascript" src="main.js"></script>
		<script type="text/javascript" src="@{[$xtw->getpath(_GP_JOBJS, REL_WEBROOT)]}"></script>
		<script type="text/javascript" src="@{[$xtw->getpath(_GP_NODEJS, REL_WEBROOT)]}"></script>
		<script type="text/javascript" src="@{[$xtw->getpath(_GP_YODJS, REL_WEBROOT)]}"></script>
	</head>
	<body>
		<map name="zoom">
			<area href="$url_view{back}" shape="rect" alt="zoom out" coords="0,35,71,71" />
			<area href="$url_view{forw}" shape="rect" alt="zoom in" coords="0,0,71,34" />
		</map>
		<map name="horz">
			<area href="$url_view{left}" shape="rect" alt="rotate left" coords="37,0,71,71" />
			<area href="$url_view{right}" shape="rect" alt="rotate right" coords="0,0,36,71" />
		</map>
		<map name="vert">
			<area href="$url_view{up}" shape="rect" alt="rotate up" coords="0,36,71,71" />
			<area href="$url_view{down}" shape="rect" alt="rotate down" coords="0,0,71,35" />
		</map>
EOF

my %p_extra = ();
$p_extra{clicku} = $clicku if $clicku ne -1;
$p_extra{clickv} = $clickv if $clickv ne -1;
my $plot_url = make_url("plot.pl", \%p, %p_extra);
my $click_url = make_url($uri, \%p);

my $p_w = 800;
my $p_h = 600;

my $img_attr = qq{border="0" style="vertical-align: middle; padding: 3px"};

my %p_smode = %p;
delete $p_smode{job};
delete $p_smode{hl};

my %p_reload = %p;
delete $p_reload{sid};

my %urls = (
	temp	=> make_url($uri, \%p_smode, smode => "temp"),
	jobs	=> make_url($uri, \%p_smode, smode => "jobs"),
	wired	=> make_url($uri, \%p, vmode => "wiredone"),
	phys	=> make_url($uri, \%p, vmode => "physical"),
	reload => make_url($uri, \%p_reload),
	login => make_url($uri, \%p),
);
$urls{login} = "https://" . $cgi->server_name() . $urls{login};

print <<EOF;
		<table border="0" cellspacing="0" cellpadding="0">
			<tr valign="top">
				<td>
						<a href="$urls{temp}"><img alt="[temp]"  src="img/temp.png" $img_attr /></a><br />
						<a href="$urls{jobs}"><img alt="[jobs]"  src="img/jobs.png" $img_attr /></a><br />
						<a href="$urls{wired}"><img alt="[wired]" src="img/wired.png" $img_attr /></a><br />
						<a href="$urls{phys}"><img alt="[phys]"  src="img/phys.png" $img_attr /></a><br />
						<a href="$urls{reload}"><img alt="[reload]" src="img/reload.png" $img_attr /></a><br />
						<!-- img alt="[pan]" usemap="#pan" src="img/pan.png" $img_attr / -->
						<img alt="[zoom]" usemap="#zoom" src="img/zoom.png" $img_attr /><br />
						<img alt="[horz]" usemap="#horz" src="img/rot-horz.png" $img_attr /><br />
						<img alt="[vert]" usemap="#vert" src="img/rot-vert.png" $img_attr /></td>
				<td>
				 <a href="${click_url}click="><img alt="[3d]" border="0" src="$plot_url"
				  width="$p_w" height="$p_h" ismap="ismap" style="border: 1px solid white; margin-right: 2px" /></a><br />
				<div class="micro" style="float: right">
					<a href="mailto:support\@psc.edu">Help</a> | Copyright &copy; 2005-2006
				  <a href="http://www.psc.edu/">Pittsburgh Supercomputing Center</a></div>
EOF

if (!$xtw->logged_in) {
	print qq!<div class="micro"><a href="$urls{login}">Login</a></div>!;
}

print <<EOF;
</td>
				<td style="white-space: nowrap">
					<b>- Node Legend -</b><br />
EOF

if (($p{smode} || "") eq "temp") {
	print <<EOF;
					<div class="job" style="background-color: rgb(255,153,153)"></div>75-80C <br clear="all" />
					<div class="job" style="background-color: rgb(255,0,0)    "></div>71-75C <br clear="all" />
					<div class="job" style="background-color: rgb(255,153,0)  "></div>66-71C <br clear="all" />
					<div class="job" style="background-color: rgb(255,204,51) "></div>62-66C <br clear="all" />
					<div class="job" style="background-color: rgb(255,255,0)  "></div>57-62C <br clear="all" />
					<div class="job" style="background-color: rgb(102,255,0)  "></div>53-57C <br clear="all" />
					<div class="job" style="background-color: rgb(0,204,0)    "></div>49-53C <br clear="all" />
					<div class="job" style="background-color: rgb(0,153,153)  "></div>44-49C <br clear="all" />
					<div class="job" style="background-color: rgb(0,0,255)    "></div>40-44C <br clear="all" />
					<div class="job" style="background-color: rgb(51,51,255)  "></div>35-40C <br clear="all" />
					<div class="job" style="background-color: rgb(102,0,204)  "></div>31-35C <br clear="all" />
					<div class="job" style="background-color: rgb(153,0,153)  "></div>26-31C <br clear="all" />
					<div class="job" style="background-color: rgb(204,0,102)  "></div>22-26C <br clear="all" />
					<div class="job" style="background-color: rgb(0,0,102)    "></div>18-22C <br clear="all" />
EOF
} else {
	if (open FH, "< " . $xtw->getpath(_GP_LEGEND)) {
		local $/;
		local $_ = <FH>;
		s/<\/?td.*?>//g;
		print;
		close FH;
	}
}

my $s = <<EOF;
<br />
					<div id="pl_job">
						<b>- Job Information -</b><br />
						No job selected (select one from the list above).</div><br />
					<div id="pl_node">
						<b>- Node Information -</b><br />
						No node selected (select one from the plot).</div>
</td>
			</tr>
		</table>
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

# vim: set ts=2:
