#!/usr/bin/perl
# $Id$

use lib qw(../lib);
use POSIX;
use XTWMon;
use XTWMon::Color;

use strict;
use warnings;

use constant _PATH_WIMAP =>	"/home/yanovich/code/proj/xt3dmon/data/rtrtrace";
use constant _PATH_JOBMAP =>	"/home/yanovich/code/proj/xt3dmon/data/nids_list_phantom";
use constant _PATH_QSTAT =>	"/home/yanovich/code/proj/xt3dmon/data/qstat.out";

use constant ST_FREE	=> 0;
use constant ST_DOWN	=> 1;
use constant ST_USED	=> 2;
use constant ST_SERV	=> 3;
use constant ST_UNAC	=> 4;

use constant SLEEP_INTV => 5000;

use constant ST_MTIME => 9;

my $out_dir = _PATH_LATEST;

my @statecol = (
	[255, 255, 255],	# FREE
	[255, 0, 0],		# DOWN
	[0, 0, 0],		# USED
	[255, 255, 0],		# SERV
	[51, 51, 255],		# UNAC
);

# end config

my @nodes;
my @invmap;
my %jobs;
my @freenodes;
my @disnodes;

parse_wimap();

for (;;) {
	if (-d $out_dir) {
		my $ts = (stat $out_dir)[ST_MTIME];
		my $dst = strftime(_PATH_ARCHIVE, localtime $ts);
		rename($out_dir, $dst) || err("rename: $out_dir to $dst");
	}
	mkdir $out_dir, 0755 || err("mkdir: $out_dir");
	foreach (@{ &SKEL_DIRS }) {
		mkdir "$out_dir/$_", 0755 || err("mkdir: $out_dir/$_");
	}

	parse_jobmap();
	parse_qstat();

	write_jobfiles()			if %jobs;
	write_nodes(_PATH_FREE, \@freenodes)	if @freenodes;
	write_nodes(_PATH_DISABLED, \@disnodes)	if @disnodes;

exit;
	sleep(SLEEP_INTV);
}

sub err {
	(my $progname = $0) =~ s!.*/!!;
	die("$progname: $!: " . join('', @_) . "\n");
}

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
		}x;
		next unless @m;

		my ($nid, $cb, $r, $cg, $m, $n, $x, $y, $z) = @m;

		$nodes[$x] = [] unless ref $nodes[$x] eq "ARRAY";
		$nodes[$x][$y] = [] unless ref $nodes[$x][$y] eq "ARRAY";
		$invmap[$nid] = $nodes[$x][$y][$z] = {
			nid	=> $nid,
			col	=> $statecol[ST_FREE],
			x	=> $x,
			y	=> $y,
			z	=> $z
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
			$node->{col} = $statecol[ST_DOWN];
			push @disnodes, $node;
		} elsif ($jobid) {
			$node->{col} = \$j->{col};
			push @{ $j->{nodes} }, $node;
		} else {
			$node->{col} = $statecol[ST_FREE];
			push @freenodes, $node;
		}
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
		nodes => []
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
		qq{</script>							};
EOF
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

	my $n = 3; # free, down, service
	my $max = scalar(keys(%jobs)) + $n;
	my $npercols = int($max / 3); # 4 columns (3+1)

	$fn = _PATH_LEGEND;
	open LEGENDF, "> $fn" or err($fn);
	print LEGENDF <<EOF;
	@{[sepcols(0, $npercols)]}
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_FREE] }]});"></div>
	@{[js_dynlink("Free", "mkurl_hl('free')")]}<br />
	@{[sepcols(1, $npercols)]}
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_DOWN] }]});"></div>
	@{[js_dynlink("Down (PBS)", "mkurl_hl('down')")]}<br />
	@{[sepcols(2, $npercols)]}
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_SERV] }]});"></div>
	@{[js_dynlink("Service", "mkurl_hl('service')")]}<br />
EOF

	foreach $jobid (sort { $a <=> $b } keys %jobs) {
		$job = $jobs{$jobid};
		# XXX: sanity check?
		$fn = subst(_PATH_JOB, id => $jobid);
		write_nodes($fn, $job->{nodes});

		print LEGENDF sepcols($n, $npercols);

		my $col = join ',', @{ $job->{col} };
		print LEGENDF <<HTML;
	<div class="job" style="background-color: rgb($col);"></div>
	@{[js_dynlink("Job $jobid", "mkurl_job($jobid)")]}<br clear="all" />
HTML
		print JSF "\n\tj = new Job($jobid)\n";
		foreach (qw(name owner queue dur_used dur_want ncpus mem)) {
			print JSF "\tj.$_ = '$job->{$_}'\n" if exists $job->{$_};
		}
		$n++;
	}
	close LEGENDF;

	print JSF <<JS;
}
_jinit()
JS
	close JSF;
}

sub write_nodes {
	my ($fn, $r_nodes) = @_;
	local *F;

	open F, "> $fn" or err($fn);
	print F "@$_{qw(x y z)}\n" foreach (@$r_nodes);
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
