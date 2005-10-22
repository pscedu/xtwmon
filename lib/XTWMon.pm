#!/usr/bin/perl
# $Id$

package XTWMon;

use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	_PATH_LATEST_FINAL

	_GP_DISABLED _GP_FREE
	_GP_JOB _GP_JOBJS _GP_LEGEND
	subst sid_gen sid_valid

	ZOOM_MIN ZOOM_MAX

	REL_SYSROOT REL_WEBROOT
);

use constant _PATH_LATEST_FINAL	=> "/var/www/html/xtwmon/www/latest";

# Need trailing slash below.
use constant _PATH_CLI_ROOT	=> "/var/www/html/xtwmon/www/sessions";

# All paths must be absolute, since mod_perl has strange cwds.
use constant _GP_JOBJS		=> 0;
use constant _GP_LEGEND		=> 1;

use constant CLI_SKEL_DIRS	=> [qw(jobs)];

use constant ZOOM_MAX		=> 100;
use constant ZOOM_MIN		=> -100;

# strftime(3)
use constant _PATH_ARCHIVE	=> "/var/www/html/xtwmon/www/data-%Y-%m-%d-tm-%H-%M-%S";

use constant REL_SYSROOT => 0;
use constant REL_WEBROOT => 1;

sub new {
	my ($class, $sid) = @_;
	$sid = sid_gen() unless sid_valid($sid);
	return bless {
		sid	=> $sid,
	}, $class;
}


sub getpath {
	my ($obj, $res, $rel) = @_;
	$rel = REL_SYSROOT unless defined $rel;
	my $prefix = ($rel == REL_WEBROOT) ? "sessions" : _PATH_CLI_ROOT ;
	return ($prefix . "/" . $obj->{sid} . (
		"/jobs.js",		# _GP_JOBJS
		"/legend.html"		# _GP_LEGEND
	)[$res]);
}

sub subst {
	my ($value, %subs) = @_;
	my ($k, $v);
	while (($k, $v) = each %subs) {
		warn "$k: no value set\n" unless defined $v;
		$value =~ s/%{$k}/$v/g;
	}
	return ($value);
}

use constant SID_LEN => 12;

sub sid_gen {
	my $sid;
	do {
		$sid = "";
		while (length($sid) != SID_LEN) {
			my $ch = int rand 255;
			$sid .= chr($ch) if chr($ch) =~ /^[a-zA-Z0-9]$/;
		}
	} while (sid_valid($sid));
	sess_create($sid);
	return ($sid);
}

sub sid_valid {
	my ($sid) = @_;
	return (defined $sid && $sid =~ /^[a-zA-Z0-9]$/ &&
	    -d _PATH_CLI_ROOT . "/$sid");
}

use File::Find;
use File::Copy;

sub sess_create {
	my ($sid) = @_;
	my $out_dir = _PATH_CLI_ROOT . "/$sid";
	mkdir $out_dir, 0755; # XXX or die
	foreach (@{ &CLI_SKEL_DIRS }) {
		mkdir "$out_dir/$_", 0755;
	}
	find(sub {
		my $file = $File::Find::name;
		my $dir = _PATH_LATEST_FINAL;
		$file =~ s/\Q$dir\E/$out_dir/;
		copy($File::Find::name, $file);
	}, _PATH_LATEST_FINAL);
}

1;
