#!/usr/bin/perl
# $Id$

use lib qw(../lib);
use POSIX;
use XTWMon;
use XTWMon::Color;
use File::Find;
use File::Copy;
use File::Path;
use CGI;

use strict;
use warnings;

use constant _PATH_WIMAP	=> "/home/yanovich/code/proj/xt3dmon/data/rtrtrace";
use constant _PATH_JOBMAP	=> "/home/yanovich/code/proj/xt3dmon/data/nids_list_phantom";
use constant _PATH_QSTAT	=> "/home/yanovich/code/proj/xt3dmon/data/qstat.out";

use constant _PATH_LATEST	=> "/var/www/html/xtwmon/www/latest-tmp";
use constant _PATH_LATEST_DUMMY	=> "/var/www/html/xtwmon/www/latest-old";

use constant _PATH_JOBJS	=> _PATH_LATEST . "/jobs.js";
use constant _PATH_LEGEND	=> _PATH_LATEST . "/legend.html";
use constant _PATH_NODEJS	=> _PATH_LATEST . "/nodes.js";

use constant SKEL_DIRS		=> [qw()];

use constant ST_FREE		=> 0;
use constant ST_DOWN		=> 1;
use constant ST_DISABLED	=> 2;
use constant ST_USED		=> 3;
use constant ST_SVC		=> 4;
use constant ST_BAD		=> 5;
use constant ST_CHECK		=> 6;

use constant ST_MTIME => 9;

my $out_dir = _PATH_LATEST;
my $cgi = CGI->new;

my @statecol = (
	[255, 255, 255],	# FREE
	[ 51,  51,  51],	# DOWN
	[255,   0,   0],	# DISABLED
	[  0,   0,   0],	# USED
	[255, 255,   0],	# SVC
	[255, 153, 153],	# BAD
	[  0, 255,   0],	# CHECK
);

# end config

my @nodes;
my @invmap;
my %jobs;

parse_wimap();

mkdir $out_dir, 0755 || err("mkdir: $out_dir");
foreach (@{ &SKEL_DIRS }) {
	mkdir "$out_dir/$_", 0755 || err("mkdir: $out_dir/$_");
}

parse_jobmap();
parse_qstat();

write_jobfiles();
write_nodefiles();

# XXX: race
rename(_PATH_LATEST_FINAL, _PATH_LATEST_DUMMY)	or err("rename final to dummy");
rename(_PATH_LATEST, _PATH_LATEST_FINAL)	or err("rename tmp to final");
rmtree(_PATH_LATEST_DUMMY, 0, 0);

exit;

sub err {
	(my $progname = $0) =~ s!.*/!!;
	die("$progname: " . join('', @_) . ": $!\n");
}

my %stmap = (
	c => ST_FREE,
	n => ST_DOWN,
	i => ST_SVC,
);

sub parse_wimap {
	local ($_, *WIMAP);
	open WIMAP, "< " . _PATH_WIMAP or err(_PATH_WIMAP);
	while (<WIMAP>) {
		# nid coord x,y,z
		my @m = m{^
			\s*
			(\d+)				# nid ($1)
			\s+

			c(\d+)-(\d+)c(\d+)s(\d+)s(\d+)	# coord ($2-$6)
			\s+

			(\d+),(\d+),(\d+)		# xyz ($7-$9)
			\s+

			([cin])				# st ($10)
		}x;
		next unless @m;

		my ($nid, $cb, $r, $cg, $m, $n, $x, $y, $z, $st) = @m;

		$nodes[$x] = [] unless ref $nodes[$x] eq "ARRAY";
		$nodes[$x][$y] = [] unless ref $nodes[$x][$y] eq "ARRAY";
		$invmap[$nid] = $nodes[$x][$y][$z] = {
			nid	=> $nid,
			st	=> $stmap{$st},
			col	=> undef,
			x	=> $x,
			y	=> $y,
			z	=> $z,
			r	=> $r,
			cb	=> $cb,
			cg	=> $cg,
			m	=> $m,
			n	=> $n,
			st	=> $st,
		};
	}
	close WIMAP;
}

sub parse_jobmap {
	local ($_, *JMAP);
	open JMAP, "< " . _PATH_JOBMAP or err(_PATH_JOBMAP);
	while (<JMAP>) {
		# nid enabled jobid
		my @m = m{^
			\s*
			(\d+)			# nid ($1)
			\s+
			(\d+)			# enabled ($2)
			\s+
			(\d+)			# jobid ($3)
		}x;
		next unless @m;
		my ($nid, $enabled, $jobid) = @m;
		next unless $invmap[$nid];
		my $j = $invmap[$nid]{job} = job_get($jobid);
		my $node = $invmap[$nid];

		if ($enabled == 0) {
			$node->{st} = ST_DISABLED;
		} elsif ($jobid) {
			$node->{st} = ST_USED;
			$node->{jobid} = $jobid;
			$node->{col} = \$j->{col};
		}
		$node->{col} = $statecol[$node->{st}] unless $node->{col};
	}
	close JMAP;

	my @keys = sort { $a <=> $b } keys %jobs;
	my $len = scalar @keys;
	my $t = 0;
	foreach my $j (@keys) {
		$jobs{$j}{col} = col_get($t++, $len);
	}
}

sub parse_qstat {
	local ($_, *QSTAT);
	my $eof;

	my %j = (state => "", id => 0);
	open QSTAT, "< " . _PATH_QSTAT or err(_PATH_QSTAT);
	for (;;) {
		$eof = eof QSTAT;
		defined($_ = <QSTAT>) && chomp;
		if ($eof or /^Job Id: (\d+)/) {
			# Save old job
			if ($j{state} eq 'R' && exists $jobs{$j{id}}) {
				@{ $jobs{$j{id}} }{keys %j} = values %j;
			}
			last if $eof;
			# Set up next job
			%j = (id => $1, state => "");
		} elsif (/^\s*Job_Name = /) {
			$j{name} = $';
		} elsif (/^\s*Job_Owner = (.*?)/) { # XXX
			$j{owner} = $';
			$j{owner} =~ s/@.*//;
		} elsif (/^\s*job_state = (.)/) {
			$j{state} = $1;
		} elsif (/^\s*queue = /) {
			$j{queue} = $';
		} elsif (/^\s*Resource_List\.size = (\d+)/) {
			$j{ncpus} = $1;
		} elsif (/^\s*Resource_List\.walltime = (\d\d):(\d\d)/) {
			$j{dur_want} = $1 * 60 + $2;
		} elsif (/^\s*resources_used\.walltime = (\d\d):(\d\d)/) {
			$j{dur_used} = $1 * 60 + $2;
		} elsif (/^\s*resources_used\.mem = (\d+)kb/) {
			$j{mem} = $1;
		}
	}
	close QSTAT;
}

sub job_get {
	my ($jobid) = shift;
	return undef unless $jobid;
	return $jobs{$jobid} if $jobs{$jobid};
	$jobs{$jobid} = {
		id => $jobid,
	};
}

# Arguments are the link text and Javascript code that
# returns a URL.
sub js_dynlink {
	my ($desc, $js) = @_;
	return	qq{<script type="text/javascript">				} .
		qq{<!--\n							} .
		qq{	document.write('<a href="' + $js + '">$desc</a>')	} .
		qq{// -->							} .
		qq{</script>};
}

sub sepcols {
	my ($pos, $incr) = @_;
	return $pos == 0 || $pos % $incr ?
	    "" : q{</td><td width="10%">};
}

sub write_jobfiles {
	my ($jobid, $job, $fn);
	local (*LEGENDF, *JSF);

	$fn = _PATH_JOBJS;
	open JSF, "> $fn" or err($fn);
	print JSF <<JS;
function _jinit() {
	var j
JS

	$fn = _PATH_LEGEND;
	open LEGENDF, "> $fn" or err($fn);
	print LEGENDF <<EOF;
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_FREE] }]});"></div>
	@{[js_dynlink("Free", "mkurl_hl('free')")]}<br clear="all" />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_DOWN] }]});"></div>
	@{[js_dynlink("Down (HW)", "mkurl_hl('down')")]}<br clear="all" />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_DISABLED] }]});"></div>
	@{[js_dynlink("Disabled (PBS)", "mkurl_hl('disabled')")]}<br />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_SVC] }]});"></div>
	@{[js_dynlink("Service", "mkurl_hl('service')")]}<br clear="all" />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_BAD] }]});"></div>
	@{[js_dynlink("Bad", "mkurl_hl('bad')")]}<br clear="all" />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_CHECK] }]});"></div>
	@{[js_dynlink("Checking", "mkurl_hl('check')")]}<br clear="all" />
EOF

	my $n = 0; # free, disabled, service
	my $max = scalar(keys(%jobs)) + $n;
	my $npercols = int($max / 2 + .5); # 3 columns (2+1)

	foreach $jobid (sort { $a <=> $b } keys %jobs) {
		$job = $jobs{$jobid};

		print LEGENDF sepcols($n++, $npercols);

		my $col = join ',', @{ $job->{col} };
		# XXX: owner name and JS characters
		my $ltext = defined $job->{owner} ? $job->{owner} : $job->{id};
		print LEGENDF <<HTML;
	<div class="job" style="background-color: rgb($col);"></div>
	@{[js_dynlink($cgi->escapeHTML($ltext), "mkurl_job($jobid)")]}<br clear="all" />
HTML
		print JSF "\n\tj = new Job($jobid)\n";
		foreach (qw(name owner queue dur_used dur_want ncpus mem)) {
			print JSF "\tj.$_ = '$job->{$_}'\n" if exists $job->{$_};
		}
	}
	close LEGENDF;

	print JSF <<JS;
}
_jinit()
JS
	close JSF;
}

sub write_nodefiles {
	my $fn;
	local (*F, $_);

	$fn = _PATH_NODEJS;
	open F, "> $fn" or err($fn);
	print F <<EOF;
function _ninit() {
	var n
EOF

	foreach my $node (@invmap) {
		next unless ref $node eq "HASH";

		print F <<EOF;
	n = new Node($node->{nid})
EOF

		foreach (qw(x y z r cg cb m n jobid)) {
			print F "\tn.$_ = '$node->{$_}'\n"
			    if exists $node->{$_};
		}
	}

	print F <<EOF;
}
_ninit()
EOF
	close F;
}

sub col_get {
	my ($pos, $tot) = @_;
	my ($hinc, $vinc, $sinc);
	my ($h, $s, $v);

	$hinc = 360 / $tot;
	$sinc = (SAT_MAX - SAT_MIN) / $tot;
	$vinc = (VAL_MAX - VAL_MIN) / $tot;

	$h = $hinc * $pos + HUE_MIN;
	$s = $sinc * $pos + SAT_MIN;
	$v = $vinc * $pos + VAL_MIN;

	return (XTWMon::Color::HSV2RGB($h, $s, $v));
}

sub col_lookup {
	my ($img, $tab, $r, $g, $b) = @_;
	my $v = $r * 256 ** 2 + $g * 256 + $b;
	return $tab->{$v} if exists $tab->{$v};
	return $tab->{$v} = $img->colorAllocate($r, $g, $b);
}
