#!/usr/bin/perl
# $Id$

package XTWMon;

use Exporter;
use File::Find;
use File::Copy;
use strict;
use warnings;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	_PATH_LATEST_FINAL

	_GP_JOBJS _GP_LEGEND _GP_NODEJS
	subst sid_gen sid_valid

	ZOOM_MIN ZOOM_MAX

	REL_SYSROOT REL_WEBROOT

	make_url
	hl_valid vmode_valid smode_valid
);

use constant _PATH_LATEST_FINAL	=> "/var/www/html/xtwmon/www/latest";

# Need trailing slash below.
use constant _PATH_CLI_ROOT	=> "/var/www/html/xtwmon/www/sessions";

# All paths must be absolute, since mod_perl has strange cwds.
use constant _GP_JOBJS		=> 0;
use constant _GP_LEGEND		=> 1;
use constant _GP_NODEJS		=> 2;

use constant CLI_SKEL_DIRS	=> [qw(jobs)];

use constant ZOOM_MAX		=> 100;
use constant ZOOM_MIN		=> -100;

# strftime(3)
use constant _PATH_ARCHIVE	=> "/var/www/html/xtwmon/www/data-%Y-%m-%d-tm-%H-%M-%S";

use constant REL_SYSROOT => 0;
use constant REL_WEBROOT => 1;

use constant SID_LEN => 12;

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
		"/legend.html",		# _GP_LEGEND
		"/nodes.js",		# _GP_NODEJS
	)[$res]);
}

sub make_url {
	my ($page, $rp, %params) = @_;
	my $url = $page . "?";
	foreach (keys %$rp) {
		if (exists $params{$_}) {
			$url .= "$_=$params{$_}&amp;";
			delete $params{$_};
		} elsif (exists $rp->{$_} && $rp->{$_}) {
			$url .= "$_=$rp->{$_}&amp;";
		}
	}
	foreach (keys %params) {
		$url .= "$_=$params{$_}&amp;";
	}
	return ($url);
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

sub in_strarray {
	my ($needle, $r_hay) = @_;
	foreach my $i_straw (@$r_hay) {
		return (1) if $i_straw eq $needle;
	}
	return (0);
}

sub hl_valid {
	my ($hl) = @_;
	return (0) unless defined $hl;
	my @hls = qw( free disabled down bad check service );
	return (in_strarray($hl, \@hls));
}

sub vmode_valid {
	my ($vmode) = @_;
	return (0) unless defined $vmode;
	my @vmodes = qw( physical wiredone );
	return (in_strarray($vmode, \@vmodes));
}

sub smode_valid {
	my ($smode) = @_;
	return (0) unless defined $smode;
	my @smodes = qw( temp jobs );
	return (in_strarray($smode, \@smodes));
}

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
	return (defined $sid && $sid =~ /^[a-zA-Z0-9]+$/ &&
	    -d _PATH_CLI_ROOT . "/$sid");
}

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
