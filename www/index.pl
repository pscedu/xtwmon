#!/usr/bin/perl -W
# $Id$

use lib qw(../lib);
use XTWMon;
use CGI;
use strict;
use warnings;

my $r = shift;
$r->content_type('text/html');
my $cgi = CGI->new();

$r->print(<<EOF);
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>BigBen XT3 Monitor</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
	</head>
	<body>
		<h1>PSC XT3 - Out of Service</h1>
		<p>Our Cray XT3 is no longer operational.</p>
		<hr />
		<a href="http://www.psc.edu/">PSC</a>
	</body>
</html>
EOF

exit;

my $xtw = XTWMon->new(cgi => $cgi);

my %p;
$p{t} = $cgi->param("t");
$p{p} = $cgi->param("p");
$p{z} = $cgi->param("z");
$p{hl} = $cgi->param("hl");
$p{vmode} = $cgi->param("vmode");
$p{smode} = $cgi->param("smode");
$p{sid} = $xtw->{sid};

#
#unless (defined $req_sid and $req_sid eq $p{sid}) {
#	print $cgi->redirect(make_url($r->uri, \%p));
#	exit;
#}

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

my %np = (
	tpbg => ($p{t} - 30) % 360,
	tnbg => ($p{t} + 30) % 360,
	ppbg => ($p{p} - 20) % 360,
	pnbg => ($p{p} + 20) % 360,
	zpbg => $p{z} - 20,
	znbg => $p{z} + 20,

	tpsm => ($p{t} - 15) % 360,
	tnsm => ($p{t} + 15) % 360,
	ppsm => ($p{p} - 10) % 360,
	pnsm => ($p{p} + 10) % 360,
	zpsm => $p{z} - 10,
	znsm => $p{z} + 10,
);

# Bounds.
$np{ppbg} = 270 if $p{p} >= 270 && $np{ppbg} < 270;
$np{pnbg} =  90 if $p{p} <=  90 && $np{pnbg} >  90;

$np{ppsm} = 270 if $p{p} >= 270 && $np{ppsm} < 270;
$np{pnsm} =  90 if $p{p} <=  90 && $np{pnsm} >  90;

$p{z} = ZOOM_MAX if $p{z} > ZOOM_MAX;
$p{z} = ZOOM_MIN if $p{z} < ZOOM_MIN;

$np{zpbg} = ZOOM_MAX if $np{zpbg} > ZOOM_MAX;
$np{zpbg} = ZOOM_MIN if $np{zpbg} < ZOOM_MIN;

$np{zpsm} = ZOOM_MAX if $np{zpsm} > ZOOM_MAX;
$np{zpsm} = ZOOM_MIN if $np{zpsm} < ZOOM_MIN;

$np{znbg} = ZOOM_MAX if $np{znbg} > ZOOM_MAX;
$np{znbg} = ZOOM_MIN if $np{znbg} < ZOOM_MIN;

$np{znsm} = ZOOM_MAX if $np{znsm} > ZOOM_MAX;
$np{znsm} = ZOOM_MIN if $np{znsm} < ZOOM_MIN;

$p{job} = $cgi->param('job');
$p{job} = 0 unless $p{job} && $p{job} =~ /^\d+$/;

# It is imperative that all variables affecting the URL
# be set before make_url() is called.

my $uri = $r->uri;

my %url_view = (
	bg_back	=> make_url($uri, \%p, z => $np{zpbg}),
	bg_down	=> make_url($uri, \%p, p => $np{ppbg}),
	bg_forw	=> make_url($uri, \%p, z => $np{znbg}),
	bg_left	=> make_url($uri, \%p, t => $np{tnbg}),
	bg_right=> make_url($uri, \%p, t => $np{tpbg}),
	bg_up	=> make_url($uri, \%p, p => $np{pnbg}),

	sm_back	=> make_url($uri, \%p, z => $np{zpsm}),
	sm_down	=> make_url($uri, \%p, p => $np{ppsm}),
	sm_forw	=> make_url($uri, \%p, z => $np{znsm}),
	sm_left	=> make_url($uri, \%p, t => $np{tnsm}),
	sm_right=> make_url($uri, \%p, t => $np{tpsm}),
	sm_up	=> make_url($uri, \%p, p => $np{pnsm}),
);

my %js_p;
@js_p{qw(sid)} = @p{qw(sid)};

my $arb_url = $xtw->getpath(_PATH_ARBITER, REL_WEBROOT);
my %js_urls = (
	jobs	=> make_url($arb_url, \%js_p, data => "jobs"),
	nodes	=> make_url($arb_url, \%js_p, data => "nodes"),
	yods	=> make_url($arb_url, \%js_p, data => "yods"),
);

$r->print(<<EOF);
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>BigBen XT3 Monitor</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
		<link rel="stylesheet" type="text/css" href="main.css" media="screen" />
		<script type="text/javascript">
			<!--
				var defparams = []
				defparams['sid'] = '$p{sid}'
			// -->
		</script>
		<script type="text/javascript" src="main.js"></script>
		<script type="text/javascript" src="$js_urls{jobs}"></script>
		<script type="text/javascript" src="$js_urls{nodes}"></script>
		<script type="text/javascript" src="$js_urls{yods}"></script>
	</head>
	<body>
		<map name="zoom" id="zoom">
			<area href="$url_view{bg_forw}" shape="rect" alt="Zoom in"  title="Zoom In Far"	 coords="0,0,71,17" />
			<area href="$url_view{sm_forw}" shape="rect" alt="Zoom in"  title="Zoom In"	 coords="0,18,71,35" />
			<area href="$url_view{sm_back}" shape="rect" alt="Zoom out" title="Zoom Out"	 coords="0,36,71,53" />
			<area href="$url_view{bg_back}" shape="rect" alt="Zoom out" title="Zoom Out Far" coords="0,54,71,71" />
		</map>
		<map name="horz" id="horz">
			<area href="$url_view{bg_right}" shape="rect" alt="Rotate Right" title="Rotate Right"	coords="0,0,17,71" />
			<area href="$url_view{sm_right}" shape="rect" alt="Rotate Right" title="Rotate Right"	coords="18,0,35,71" />
			<area href="$url_view{sm_left}"  shape="rect" alt="Rotate Left"  title="Rotate Left"	coords="36,0,53,71" />
			<area href="$url_view{bg_left}"  shape="rect" alt="Rotate Left"  title="Rotate Left"	coords="54,0,71,71" />
		</map>
		<map name="vert" id="vert">
			<area href="$url_view{bg_down}"	shape="rect" alt="Rotate Down"	title="Rotate Down"	coords="0,0,71,17" />
			<area href="$url_view{sm_down}"	shape="rect" alt="Rotate Down"	title="Rotate Down"	coords="0,18,71,35" />
			<area href="$url_view{sm_up}"	shape="rect" alt="Rotate Up"	title="Rotate Up"	coords="0,36,71,53" />
			<area href="$url_view{bg_up}"	shape="rect" alt="Rotate Up"	title="Rotate Up"	coords="0,54,71,71" />
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
	temp	 => make_url($uri, \%p_smode, smode => "temp"),
	jobs	 => make_url($uri, \%p_smode, smode => "jobs"),
	wired	 => make_url($uri, \%p, vmode => "wiredone"),
	phys	 => make_url($uri, \%p, vmode => "physical"),
	reload => make_url($uri, \%p_reload),
	login  => make_url($uri, \%p),
);
$urls{login} = "https://" . $cgi->server_name() . $urls{login};

print <<EOF;
		<table border="0" cellspacing="0" cellpadding="0">
			<tr valign="top">
				<td>
					<a href="$urls{temp}"   title="Temperature Mode"><img   alt="[temp]"   src="img/temp.png"   $img_attr /></a><br />
					<a href="$urls{jobs}"   title="Job Mode"><img   alt="[jobs]"   src="img/jobs.png"   $img_attr /></a><br />
					<a href="$urls{wired}"  title="Wired Mode"><img  alt="[wired]"  src="img/wired.png"  $img_attr /></a><br />
					<a href="$urls{phys}"   title="Physical Mode"><img   alt="[phys]"   src="img/phys.png"   $img_attr /></a><br />
					<a href="$urls{reload}" title="Reload Data"><img alt="[reload]" src="img/reload.png" $img_attr /></a><br />
					<!-- img alt="[pan]" usemap="#pan" src="img/pan.png" $img_attr / -->
					<img alt="[zoom]" usemap="#zoom" src="img/zoom.png" $img_attr /><br />
					<img alt="[horz]" usemap="#horz" src="img/rot-horz.png" $img_attr /><br />
					<img alt="[vert]" usemap="#vert" src="img/rot-vert.png" $img_attr /></td>
				<td>
				 <a href="${click_url}click="><img alt="[3d]" border="0" src="$plot_url"
				  width="$p_w" height="$p_h" ismap="ismap"
					style="border: 1px solid #336699; margin-right: 2px" /></a><br />
				<div class="micro" style="float: right; white-space: nowrap">
					<a href="help.html" onclick="open('help.html', 'xt3dmon-help', 'width=500,height=230,resizable=1'); return false">Help</a> |
					<a href="http://www.psc.edu/~yanovich/xt3dmon/">Native Clients</a> |
					Copyright &copy; 2005-@{[(localtime)[5] + 1900]}
				  <a href="http://www.psc.edu/">Pittsburgh Supercomputing Center</a>&nbsp;</div>
EOF

if ($xtw->haspriv(PRIV_NONE)) {
	print qq!<div class="micro"><a href="$urls{login}">Login</a></div>!;
}

print <<EOF;
</td>
				<td style="white-space: nowrap">
					<b>- Node Legend -</b><br />
EOF

if (($p{smode} || "") eq "temp") {
	print <<EOF;
					<div class="job" style="border: 1px solid rgb(255,255,  0)"></div>N/A <br clear="all" />
					<div class="job" style="background-color: rgb(255,  0,  0)"></div>&gt;69C <br clear="all" />
					<div class="job" style="background-color: rgb(255,102,  0)"></div>66-69C <br clear="all" />
					<div class="job" style="background-color: rgb(255,153,  0)"></div>62-65C <br clear="all" />
					<div class="job" style="background-color: rgb(255,204,  0)"></div>58-61C <br clear="all" />
					<div class="job" style="background-color: rgb(255,255,  0)"></div>54-57C <br clear="all" />
					<div class="job" style="background-color: rgb(255,255,153)"></div>50-53C <br clear="all" />
					<div class="job" style="background-color: rgb(255,255,255)"></div>46-49C <br clear="all" />
					<div class="job" style="background-color: rgb(204,255,255)"></div>42-45C <br clear="all" />
					<div class="job" style="background-color: rgb(  0,255,255)"></div>38-41C <br clear="all" />
					<div class="job" style="background-color: rgb(  0,204,255)"></div>34-37C <br clear="all" />
					<div class="job" style="background-color: rgb(  0,153,255)"></div>30-33C <br clear="all" />
					<div class="job" style="background-color: rgb(  0,  0,255)"></div>26-29C <br clear="all" />
					<div class="job" style="background-color: rgb(  0,  0,204)"></div>22-25C <br clear="all" />
					<div class="job" style="background-color: rgb(  0,  0,102)"></div>&lt;22C <br clear="all" />

EOF
} else {
	my $pr_reg = $xtw->haspriv(PRIV_REG);
	my $pr_adm = $xtw->haspriv(PRIV_ADMIN);

	if (open FH, "<", $xtw->dynpath(_GP_LEGEND, REL_SYSROOT)) { # XXX: handle err?
		local $/;
		local $_ = <FH>;

		my @t = split m!(?=<div)!;
		foreach my $te (@t) {
			if ($te =~ /(\w+) \((job \d+)\)/) {
				# Strip account information unless it is this
				# user's job or this user is admin.
				$te =~ s/$@/$2/ unless $pr_adm or
				    ($pr_reg && $1 eq $cgi->remote_user());
			}
			print $te;
		};
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
