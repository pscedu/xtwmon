#!/usr/bin/perl
# $Id$

use strict;
use warnings;
use XTWMon::Plot;
use CGI;

my $cgi = CGI->new();

my $p = XTWMon::Plot->new(shift);
$p->setpos($cgi->param("x"), $cgi->param("y"), $cgi->param("z"));
$p->setview($cgi->param("rx"), $cgi->param("rz"),
    $cgi->param("sx"), $cgi->param("sz"));
$p->main();
