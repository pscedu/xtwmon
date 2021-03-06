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

use constant _PATH_LATEST	=> "/var/www/html/xtwmon/data/latest-tmp";
use constant _PATH_LATEST_DUMMY	=> "/var/www/html/xtwmon/data/latest-old";

use constant _PATH_JOBJS	=> _PATH_LATEST . "/jobs.js";
use constant _PATH_LEGEND	=> _PATH_LATEST . "/legend.html";
use constant _PATH_NODEJS	=> _PATH_LATEST . "/nodes.js";
use constant _PATH_YODJS	=> _PATH_LATEST . "/yods.js";

use constant ST_FREE		=> 0;
use constant ST_DOWN		=> 1;
use constant ST_DISABLED	=> 2;
use constant ST_USED		=> 3;
use constant ST_SVC		=> 4;

use constant ST_MTIME => 9;

my $out_dir = _PATH_LATEST;
my $cgi = CGI->new;

my @statecol = (
	[255, 255, 255],	# FREE
	[170, 170, 170],	# DOWN
	[255,   0,   0],	# DISABLED
	[  0,   0,   0],	# USED
	[255, 255,   0],	# SVC
);

my @statecnt = (
	0,			# FREE
	0,			# DOWN
	0,			# DISABLED
	0,			# USED
	0,			# SVC
);

# end config

my %stmap = (
	c => ST_FREE,
	n => ST_DOWN,
	i => ST_SVC,
);

my @colors;
my @nodes;
my @invmap;
my %jobs;
my %yods;

parse_colors();
parse_nodes();
parse_yods();
parse_jobs();

{
	my @keys = sort { $a <=> $b } keys %jobs;
	foreach my $k (keys %jobs) {
		$jobs{$k}{col} = col_get($k);
	}
}

mkdir $out_dir, 0755 || err("mkdir: $out_dir");

write_yodfiles();
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

sub parse_colors {
	local ($_, *COLFH);

	open COLFH, "< " . _PATH_COLORS or err(_PATH_COLORS);
	while (<COLFH>) {
		my @nums = /(\d+)/g;
		next unless @nums >= 3;
		push @colors, [ @nums[0 .. 2] ];
	}
	close COLFH;
}

sub parse_nodes {
	local ($_, *NODEFH);

	open NODEFH, "< " . _PATH_NODE or err(_PATH_NODE);
	while (<NODEFH>) {
		s/^\s+|\s$//;
		next if /^[#@]/;
		next unless $_;

		my @fields = split /\s+/, $_;
		unless (@fields == 16) {
			printf STDERR "%s:$.: malformed line: %s",
			    _PATH_NODE, $_;
			next;
		}

		# nid	r cb cg m n	x y z	stat	enabled	jobid	temp	yodid	nfails	lustat
		# 0	0 0  0  0 0	0 0 0	i	1	0	27	0	0	c
		my ($nid, $r, $cb, $cg, $m, $n, $x, $y, $z, $st, $enabled,
		    $jobid, $temp, $yodid, $nfails, $lustat) = @fields;

		my $state = $stmap{$st};
		$state = ST_DISABLED if $state eq ST_FREE and not $enabled;

		my $color = $statecol[$state];

		my $r_job = job_get($jobid);
		if (ref $r_job eq "HASH") {
			$state = ST_USED;
			$r_job->{yodid} = $yodid; # XXX
			$r_job->{cnt}++;
			$color = $r_job->{col};
		}
		$statecnt[$state]++;

		$nodes[$x]	= [] unless ref $nodes[$x]	eq "ARRAY";
		$nodes[$x][$y]	= [] unless ref $nodes[$x][$y]	eq "ARRAY";
		my $node = $invmap[$nid] = $nodes[$x][$y][$z] = {
			nid	=> $nid,
			col	=> $color,

			r	=> $r,
			cb	=> $cb,
			cg	=> $cg,
			m	=> $m,
			n	=> $n,
			x	=> $x,
			y	=> $y,
			z	=> $z,
			st	=> $state,
			job	=> $r_job,
			jobid	=> $jobid,
			temp	=> $temp,
			nfails	=> $nfails,
		};
	}
	close NODEFH;
}

sub parse_yods {
	local ($_, *YODFH);

	open YODFH, "< " . _PATH_YOD or err(_PATH_YOD);
	while (<YODFH>) {
		s/^\s+|\s$//;
		next if /^[#@]/;
		next unless $_;

		my ($y_id, $y_partid, $y_ncpus, $y_cmd) = split /\s+/, $_, 4;
		$yods{$y_id} = {
			id	=> $y_id,
			partid	=> $y_partid,
			ncpus	=> $y_ncpus,
			cmd	=> $y_cmd,
		};
	}
	close YODFH;
}

sub parse_jobs {
	local ($_, *JOBFH);

	open JOBFH, "< " . _PATH_JOB or err(_PATH_JOB);
	while (<JOBFH>) {
		s/^\s+|\s$//;
		next if /^[#@]/;
		next unless $_;

		my ($j_id, $j_owner, $j_tmdur, $j_tmuse, $j_mem,
		    $j_ncpus, $j_queue, $j_name) = split /\s+/, $_, 8;
		next unless $jobs{$j_id};
		$jobs{$j_id}{name}	= $j_name;
		$jobs{$j_id}{owner}	= $j_owner;
		$jobs{$j_id}{queue}	= $j_queue;
		$jobs{$j_id}{ncpus}	= $j_ncpus;
		$jobs{$j_id}{dur_want}	= $j_tmdur;
		$jobs{$j_id}{dur_used}	= $j_tmuse;
		$jobs{$j_id}{mem}	= $j_mem;

		# Since the yod info is available, check
		# if this job is running single-core.
		if (exists $jobs{$j_id}{yodid}) {
			my $y_id = $jobs{$j_id}{yodid};

			$jobs{$j_id}{singlecore} = 1 if
			    exists $yods{$y_id} &&
			      $yods{$y_id}{cmd} =~ /\s-SN\b/;
		}
	}
	close JOBFH;
}

sub job_get {
	my ($jobid) = shift;
	return undef unless $jobid;
	return $jobs{$jobid} if $jobs{$jobid};
	$jobs{$jobid} = {
		id  => $jobid,
		cnt => 0,
	};
}

sub write_yodfiles {
	my ($yodid, $yod, $fn);
	local *JSF;

	$fn = _PATH_YODJS;
	open JSF, "> $fn" or err($fn);
	print JSF <<JS;
function _yinit() {
	var y
JS

	while (($yodid, $yod) = each %yods) {
		print JSF "\n\ty = new Yod($yodid)\n";
		foreach (qw(ncpus cmd partid)) {
			print JSF "\ty.$_ = '$yod->{$_}'\n";
		}
	}

	print JSF <<JS;
}
_yinit()
JS
	close JSF;
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
	@{[js_dynlink("Free ($statecnt[ST_FREE])", "mkurl_hl('free')")]}<br clear="all" />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_DOWN] }]});"></div>
	@{[js_dynlink("Down/CPA ($statecnt[ST_DOWN])", "mkurl_hl('down')")]}<br clear="all" />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_SVC] }]});"></div>
	@{[js_dynlink("Service ($statecnt[ST_SVC])", "mkurl_hl('service')")]}<br clear="all" />
	<div class="job" style="border-color: white"></div>
	@{[js_dynlink("Show all nodes", "mkurl_job(0)")]}<br clear="all" />
	<br />Nodes allocated: $statecnt[ST_USED]<br />
EOF

	foreach $jobid (sort { $a <=> $b } keys %jobs) {
		$job = $jobs{$jobid};

		my $col = join ',', @{ $job->{col} };

		my $lncpus = (exists $job->{ncpus} && defined $job->{ncpus} ?
		    $job->{ncpus} : "?");

		# XXX: owner name and JS characters
		my $ltext = q{'} . <<EOJS . q{'};
	+ (jobs[$jobid].owner ?
		(jobs[$jobid].name ?
			jobs[$jobid].owner + '/' + jobs[$jobid].name + ' ($lncpus)' :
			jobs[$jobid].owner + '/$jobid ($lncpus)') :
		'job $jobid ($lncpus)') +
EOJS

		print LEGENDF <<HTML;
	<div class="job" style="background-color: rgb($col);"></div>
	@{[js_dynlink($ltext, "mkurl_job($jobid)")]}<br clear="all" />
HTML
		print JSF "\n\tj = new Job($jobid)\n";
		foreach (qw(owner name queue dur_used dur_want ncpus mem
		    yodid singlecore)) {
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
		print F "\n\tn = new Node($node->{nid})\n";
		foreach (qw(x y z r cg cb m n jobid st temp)) {
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
	my ($id) = @_;
	return $colors[$id % @colors];
}

sub col_lookup {
	my ($img, $tab, $r, $g, $b) = @_;
	my $v = $r * 256 ** 2 + $g * 256 + $b;
	return $tab->{$v} if exists $tab->{$v};
	return $tab->{$v} = $img->colorAllocate($r, $g, $b);
}
