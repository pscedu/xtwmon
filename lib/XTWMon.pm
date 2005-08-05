#!/usr/bin/perl
# $Id$

package XTWMon;

use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	_PATH_JOBPREFIX _PATH_JOBLEGEND
	_PATH_DISABLED _PATH_FREE
	_PATH_X _PATH_Y _PATH_Z
	_PATH_LATEST _PATH_ARCHIVE
);

# Must be absolute, since mod_perl puts you in strange places.
use constant _PATH_DISABLED	=> "/var/www/html/xtwmon/www/latest/disabled";
use constant _PATH_FREE		=> "/var/www/html/xtwmon/www/latest/free";
use constant _PATH_JOBPREFIX	=> "/var/www/html/xtwmon/www/latest/jid_";
use constant _PATH_X		=> "/var/www/html/xtwmon/www/latest/x";
use constant _PATH_Y		=> "/var/www/html/xtwmon/www/latest/y";
use constant _PATH_Z		=> "/var/www/html/xtwmon/www/latest/z";
use constant _PATH_JOBLEGEND	=> "/var/www/html/xtwmon/www/latest/jobs.html";

# Need trailing slash below.
use constant _PATH_LATEST	=> "/var/www/html/xtwmon/www/latest/";

# strftime(3)
use constant _PATH_ARCHIVE	=> "/var/www/html/xtwmon/www/data-%Y-%m-%d-tm-%H-%M";

1;
