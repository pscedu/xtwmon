#!/usr/bin/perl
# $Id$

package XTWMon;

use Exporter;
use File::Find;
use File::Copy;
use CGI;
use strict;
use warnings;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	PRIV_NONE PRIV_REG PRIV_ADMIN
	haspriv

	_GP_JOBJS _GP_LEGEND _GP_NODEJS _GP_YODJS
	subst sid_valid

	_PATH_LATEST_FINAL _PATH_SYSROOT _PATH_ARBITER

	REL_SYSROOT REL_WEBROOT

	ZOOM_MIN ZOOM_MAX

	make_url
	hl_valid vmode_valid smode_valid jsdata_valid

	XCF_REQSID
);

use constant PRIV_NONE		=> 0;
use constant PRIV_REG		=> 1;
use constant PRIV_ADMIN		=> 2;

# "Dynamically generated" (based on client session ID).
use constant _GP_JOBJS		=> 0;
use constant _GP_LEGEND		=> 1;
use constant _GP_NODEJS		=> 2;
use constant _GP_YODJS		=> 3;

use constant _PATH_SYSROOT	=> "/var/www/html/xtwmon/www";
use constant _PATH_WEBROOT	=> "/xtwmon/www";

use constant _PATH_LATEST_FINAL	=> "/var/www/html/xtwmon/data/latest";
use constant _PATH_CLI_ROOT	=> "/var/www/html/xtwmon/data/sessions";
use constant _PATH_ARBITER	=> "/arbiter.pl";

use constant REL_SYSROOT	=> 0;
use constant REL_WEBROOT	=> 1;

use constant ZOOM_MAX		=> 100;
use constant ZOOM_MIN		=> -100;

use constant SID_LEN		=> 12;

use constant XCF_REQSID		=> (1<<0);

sub new {
	my ($class, %p) = @_;
	$p{flags} = 0 unless exists $p{flags} and
	    defined $p{flags} and $p{flags} =~ /^\d+$/;

	my $obj = bless {
		cgi	=> $p{cgi},
		admins	=> [qw(dsimmel scott yanovich)],
	}, $class;
	my $sid = $obj->{cgi}->param("sid");
	if ($obj->sid_valid($sid)) {
		$obj->{sid} = $sid;
	} else {
		# Invalid session ID.
		exit 0 if $p{flags} & XCF_REQSID;
		$obj->{sid} = $obj->sid_gen();
	}
	return ($obj);
}

sub haspriv {
	my ($obj, $priv) = @_;
	my $loggedin = (defined $obj->{cgi}->remote_user);

	if ($priv == PRIV_NONE) {
		return (!$loggedin);
	} elsif ($priv == PRIV_REG) {
		# XXX: should ensure !in_strarray(name, admins)
		return ($loggedin);
	} elsif ($priv == PRIV_ADMIN) {
		if ($loggedin) {
			(my $uname = $obj->{cgi}->remote_user) =~ s/@.*//;
			return (in_strarray($uname, $obj->{admins}));
		}
		return (0);
	}
	return (0);
}

sub getpath {
	my ($obj, $res, $rel) = @_;
	my $prefix = ($rel == REL_WEBROOT) ? _PATH_WEBROOT : _PATH_SYSROOT;
	return ($prefix . $res);
}

sub dynpath {
	my ($obj, $res) = @_;
	return (_PATH_CLI_ROOT . "/" . $obj->{sid} . (
		"/jobs.js",		# _GP_JOBJS
		"/legend.html",		# _GP_LEGEND
		"/nodes.js",		# _GP_NODEJS
		"/yods.js",		# _GP_YODJS
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
	my @hls = qw( free disabled down service );
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

sub jsdata_valid {
	my ($jsdata) = @_;
	return (0) unless defined $jsdata;
	my @jsdata = qw( nodes jobs yods );
	return (in_strarray($jsdata, \@jsdata));
}

sub sid_gen {
	my $obj = shift;
	my $sid;
	do {
		$sid = "";
		while (length($sid) != SID_LEN) {
			my $ch = int rand 255;
			$sid .= chr($ch) if chr($ch) =~ /^[a-zA-Z0-9]$/;
		}
	} while ($obj->sid_valid($sid));
	$obj->sess_create($sid);
	return ($sid);
}

sub sid_valid {
	my ($obj, $sid) = @_;
	return (defined $sid && $sid =~ /^[a-zA-Z0-9]+$/ &&
	    -d _PATH_CLI_ROOT . "/$sid");
}

sub sess_create {
	my ($obj, $sid) = @_;
	my $out_dir = _PATH_CLI_ROOT . "/$sid";
	mkdir $out_dir, 0755 or $obj->err("mkdir");
	find(sub {
		my $file = $File::Find::name;
		my $dir = _PATH_LATEST_FINAL;
		$file =~ s/\Q$dir\E/$out_dir/;
		copy($File::Find::name, $file);
	}, _PATH_LATEST_FINAL);
}

sub err {
	my ($obj, @msg) = @_;
	print @msg, ": $!";
	exit(1);
};

1;
