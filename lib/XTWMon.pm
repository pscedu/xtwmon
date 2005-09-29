#!/usr/bin/perl
# $Id$

package XTWMon;

use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	_PATH_LATEST _PATH_DISABLED _PATH_FREE
	_PATH_JOB _PATH_JOBJS _PATH_DATA
	_PATH_IMG _PATH_IMGMAP
	_PATH_LEGEND _PATH_ARCHIVE SKEL_DIRS
	subst
);

# Need trailing slash below.
use constant _PATH_LATEST	=> "/var/www/html/xtwmon/www/latest";

# Must be absolute, since mod_perl puts you in strange places.
use constant _PATH_DISABLED	=> _PATH_LATEST . "/disabled";
use constant _PATH_FREE		=> _PATH_LATEST . "/free";
use constant _PATH_JOB		=> _PATH_LATEST . "/jobs/%{id}";
use constant _PATH_JOBJS	=> _PATH_LATEST . "/jobs.js";
use constant _PATH_DATA		=> _PATH_LATEST . "/%{dim}/%{pos}";
use constant _PATH_IMG		=> _PATH_LATEST . "/%{dim}/%{pos}.png";
use constant _PATH_IMGMAP	=> _PATH_LATEST . "/maps/%{dim}%{pos}.html";
use constant _PATH_LEGEND	=> _PATH_LATEST . "/legend.html";

use constant SKEL_DIRS		=> [qw(x y z maps jobs)];

# strftime(3)
use constant _PATH_ARCHIVE	=> "/var/www/html/xtwmon/www/data-%Y-%m-%d-tm-%H-%M-%S";

sub subst {
	my ($value, %subs) = @_;
	my ($k, $v);
	while (($k, $v) = each %subs) {
		warn "$k: no value set\n" unless defined $v;
		$value =~ s/%{$k}/$v/g;
	}
	return ($value);
}

1;
