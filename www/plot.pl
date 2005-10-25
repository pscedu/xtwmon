#!/usr/bin/perl
# $Id$

use lib qw(../lib);
use XTWMon;
use XTWMon::Plot;
use CGI;
use strict;
use warnings;

my $r = shift;
my $cgi = CGI->new();

my $job = $cgi->param("job");
my $theta = $cgi->param("t");
my $phi = $cgi->param("p");
my $zoom = $cgi->param("z");
my $clicku = $cgi->param("clicku");
my $clickv = $cgi->param("clickv");
my $hl = $cgi->param("hl");
my $sid = $cgi->param("sid");
my $vmode = $cgi->param("vmode");
my $smode = $cgi->param("smode");

$theta = 0	unless defined $theta	&& $theta	=~ /^\d+$/;
$phi = 0	unless defined $phi	&& $phi		=~ /^\d+$/;
$zoom = 0	unless defined $zoom	&& $zoom	=~ /^-?\d+$/;
$clicku = -1	unless defined $clicku	&& $clicku	=~ /^\d+$/;
$clickv = -1	unless defined $clickv	&& $clickv	=~ /^\d+$/;
$sid = ""	unless defined $sid	&& $sid		=~ /^[a-zA-Z0-9]+$/;
$vmode = ""	unless defined $vmode	&& ($vmode eq "wiredone" or $vmode eq "physical");
$smode = ""	unless defined $smode	&& ($smode eq "jobs" or $smode eq "temp");
$hl = ""	unless defined $hl && ($hl eq "service" or
					$hl eq "free" or
					$hl eq "down");


use constant PI => 3.14159265358979323;

# Starting at 0 will leave us at the top of the sphere or something bad.
use constant PHI_SHIFT => (180 + 90);

if ($phi >= 90 && $phi <= 270) {
	if ($phi < 180) {
		$phi = 89;
	} else {
		$phi = 271;
	}
}
$phi += PHI_SHIFT;

$theta *= PI / 180;
$phi *= PI / 180;

$zoom = ZOOM_MAX if $zoom > ZOOM_MAX;
$zoom = ZOOM_MIN if $zoom < ZOOM_MIN;

my $rad = 110 - $zoom;
my $x = $rad * cos($theta) * sin($phi);
my $z = $rad * sin($theta) * sin($phi);
my $y = $rad * cos($phi);
my $lx = -$x;
my $ly = -$y;
my $lz = -$z;

# This is the center of the wired view.
$x += 20;
$y += 22;
$z += 30;

my $mag = sqrt($lx**2 + $ly**2 + $lz**2);
$lx /= $mag;
$ly /= $mag;
$lz /= $mag;

my $p = XTWMon::Plot->new($r);
$p->setpos($x, $y, $z);
$p->setview($lx, $ly, $lz);
$p->setjob($job);
$p->setclick($clicku, $clickv) if $clicku ne -1 and $clickv ne -1;
$p->sethl($hl) if $hl;
$p->setsid($sid) if $sid ne "";
$p->setvmode($vmode) if $vmode;
$p->setsmode($smode) if $smode;

$r->content_type('image/png');
$p->print();
