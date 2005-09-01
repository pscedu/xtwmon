#!/usr/bin/perl
# $Id$

use XTWMon::Plot;
use CGI;
use strict;
use warnings;

my $r = shift;
my $cgi = CGI->new();

my $job = $cgi->param("job");
my $theta = $cgi->param("t");
my $phi = $cgi->param("p");

$theta = 0	unless defined $theta && $theta =~ /^\d+$/;
$phi = 0	unless defined $phi   && $phi   =~ /^\d+$/;

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

my $rad = 80;
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

my $p = XTWMon::Plot->new();
$p->setpos($x, $y, $z);
$p->setview($lx, $ly, $lz);
$p->setjob($job);

$r->content_type('image/png');
$p->print();
