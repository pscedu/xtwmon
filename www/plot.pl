#!/usr/bin/perl
# $Id$

use strict;
use warnings;
use XTWMon::Plot;
use CGI;

my $r = shift;
my $cgi = CGI->new();

my ($job, $x, $y, $z, $lx, $ly, $lz);
$job = $cgi->param("job");
$x = $cgi->param("x");
$y = $cgi->param("y");
$z = $cgi->param("z");
$lx = $cgi->param("lx");
$ly = $cgi->param("ly");
$lz = $cgi->param("lz");

my $p = XTWMon::Plot->new();
$p->setpos($x, $y, $z);
$p->setview($lx, $ly, $lz);
$p->setjob($job);

$r->content_type('image/png');
$p->print();
