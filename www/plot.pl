#!/usr/bin/perl
# $Id$

use strict;
use warnings;
use XTWMon::Plot;
use CGI;

my $r = shift;
my $cgi = CGI->new();

my ($x, $y, $z, $rx, $rz, $sx, $sz);
$x = $cgi->param("x");
$y = $cgi->param("y");
$z = $cgi->param("z");
$rx = $cgi->param("rx");
$rz = $cgi->param("rz");
$sx = $cgi->param("sx");
$sz = $cgi->param("sz");

my $p = XTWMon::Plot->new();
$p->setpos($x, $y, $z);
$p->setview($rx, $rz, $sx, $sz);
$r->content_type('image/png');
$p->gnu_plot();
