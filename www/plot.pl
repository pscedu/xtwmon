#!/usr/bin/perl
# $Id$

use strict;
use warnings;
use XTWMon::Plot;

my $p = XTWMon::Plot->new(shift);
$p->main();
