#!/usr/bin/perl
# $Id$

use lib qw(../lib);
use GD;
use POSIX;
use XTWMon;
use XTWMon::Color;

use strict;
use warnings;

use constant _PATH_WIMAP => "data/rtrtrace";
use constant _PATH_JOBMAP => "data/nids_list_phantom";
use constant _PATH_FONT => "/usr/X11R6/lib/X11/fonts/TTF/tahoma.ttf";

use constant IMG_WIDTH => 500;
use constant IMG_HEIGHT => 300;

use constant DIM_X => 0;
use constant DIM_Y => 1;
use constant DIM_Z => 2;

use constant ST_FREE	=> 0;
use constant ST_DOWN	=> 1;
use constant ST_USED	=> 2;
use constant ST_SERV	=> 3;
use constant ST_UNAC	=> 4;

use constant SLEEP_INTV => 5000;

use constant ST_MTIME => 9;

my $out_dir = _PATH_LATEST;

my @dimcol = (
	"red",			# x
	"green",		# y
	"blue"			# z
);

my @statecol = (
	[255, 255, 255],	# FREE
	[0, 0, 0],		# DOWN
	[0, 0, 0],		# USED
	[255, 255, 0],		# SERV
	[51, 51, 255],		# UNAC
);

# end config

my @max;
my @nodes;
my @invmap;
my %jobs;
my @freenodes;
my @disnodes;

parse_wimap(\@max);

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

	gen(DIM_X, $_, subst(_PATH_IMG, dim => "x", pos => $_)) foreach (0 .. $max[DIM_X]);
	gen(DIM_Y, $_, subst(_PATH_IMG, dim => "y", pos => $_)) foreach (0 .. $max[DIM_Y]);
	gen(DIM_Z, $_, subst(_PATH_IMG, dim => "z", pos => $_)) foreach (0 .. $max[DIM_Z]);

	write_jobfiles()			if %jobs;
	write_nodes(_PATH_FREE, \@freenodes)	if @freenodes;
	write_nodes(_PATH_DISABLED, \@disnodes)	if @disnodes;

exit;
	sleep(SLEEP_INTV);
}

sub cen {
	my ($img, $str, $sx, $ex, $sy, $ey, $col, $ceny) = @_;
	my $len = length($str);
#	$img->string($fn, ($sx + $ex) / 2 - $fn->width * $len / 2,
#	    $y + $fn->height, $str, $col);
	my $d_img = GD::Image->new(100, 100);
	my $fn = _PATH_FONT;
	my $sz = 8;
	my @bnd = $d_img->stringFT($col, $fn, $sz, 0, 0, 50, $str);
	my $ren_w = $bnd[2] - $bnd[0];
	my $ren_h = $bnd[1] - $bnd[7];

	my $y;
	if ($ceny) {
		$y = ($sy + $ey) / 2 + $ren_h / 2 - 1;
	} else {
		$y = $sy + $ren_h;
	}

	$img->stringFT($col, $fn, $sz, 0,
	    ($sx + $ex) / 2 - $ren_w / 2 + 1, $y, $str);
	return ($ren_w, $ren_h);
}

sub gen {
	my ($dim, $pos, $fn) = @_;
	my $img = GD::Image->new(IMG_WIDTH, IMG_HEIGHT);
	my $col_white = $img->colorAllocate(255, 255, 255);
	my $col_black = $img->colorAllocate(0, 0, 0);
	my %col = (
		"red"	=> $img->colorAllocate(255, 0, 0),
		"green"	=> $img->colorAllocate(0, 255, 0),
		"blue"	=> $img->colorAllocate(0, 0, 255),
		"white"	=> $col_white,
		"black"	=> $col_black
	);

	my @labels = (
		"YZ Plane at X=$pos",
		"XZ Plane at Y=$pos",
		"XY Plane at Z=$pos"
	);

	my @names = qw(x y z);

	my @xdim = (
		[ DIM_Z, DIM_Y ],
		[ DIM_X, DIM_Z ],
		[ DIM_X, DIM_Y ]
	);

	$img->fill(1, 1, $col{$dimcol[$dim]});
	my ($used_w, $used_h) = cen($img, $labels[$dim], 0, IMG_WIDTH,
	    0, 0, $col_black, 0);
	$used_h += 2; # Text border

	my ($udim, $vdim) = @{ $xdim[$dim] };

	my $uincr = IMG_WIDTH / ($max[$udim] + 1);
	my $vincr = (IMG_HEIGHT - $used_h) / ($max[$vdim] + 1);
	my $node_w = $uincr - 3;
	my $node_h = $vincr - 3;

	my ($upstart, $vpstart);
	$upstart = 0;
	$vpstart = $used_h;

	my ($u, $up, $v, $vp);
	my ($_x, $_y, $_z);
	if ($dim == DIM_X) {
		$_x = \$pos;
		$_y = \$v;
		$_z = \$u;
		$vincr *= -1;
		$vpstart = IMG_HEIGHT + $vincr;
	} elsif ($dim == DIM_Y) {
		$_x = \$u;
		$_y = \$pos;
		$_z = \$v;
	} elsif ($dim == DIM_Z) {
		$_x = \$u;
		$_y = \$v;
		$_z = \$pos;
		$vincr *= -1;
		$vpstart = IMG_HEIGHT + $vincr; # - 1 ?
	}

	$img->setThickness(3);
	# Draw V axes.
	for ($u = 0, $up = $upstart;
	    $u < $max[$udim] + 1;
	    $u++, $up += $uincr) {
		$img->line($up + $node_w/2, $used_h, $up + $node_w/2,
		    IMG_HEIGHT - 2 - $node_h/2, $col{$dimcol[$vdim]});
	}

	# Draw U axes.
	for ($v = 0, $vp = $vpstart;
	    $v < $max[$vdim] + 1;
	    $v++, $vp += $vincr) {
		$img->line($upstart, $vp + $node_h/2,
		    IMG_WIDTH - 2 - $node_w/2, $vp + $node_h/2,
		    $col{$dimcol[$udim]});
	}
	$img->setThickness(1);

	local (*PLANEFH, *MAPFH);
	my $planefn = subst(_PATH_DATA, dim => $names[$dim], pos => $pos);
	open PLANEFH, "> $planefn" or err($planefn);

	my $mapfn = subst(_PATH_IMGMAP, dim => $names[$dim], pos => $pos);
	open MAPFH, "> $mapfn" or err($mapfn);
	print MAPFH qq(<map name="map$names[$dim]" id="map$names[$dim]">);

	for ($u = 0, $up = $upstart;
	    $u < $max[$udim] + 1;
	    $u++, $up += $uincr) {
		for ($v = 0, $vp = $vpstart;
		    $v < $max[$vdim] + 1;
		    $v++, $vp += $vincr) {
			my $node = $nodes[$$_x][$$_y][$$_z];
			next unless $node;
			my $upp = $up + $node_w;
			my $vpp = $vp + $node_h;
			my $col = $node->{col};
			$col = $$col if ref $col eq "REF";
			$img->filledRectangle($up, $vp, $upp, $vpp,
			    $img->colorAllocate(@$col));
			$img->rectangle($up, $vp, $upp, $vpp, $col_black);
			my $xcol = XTWMon::Color::rgb_contrast(@$col);
			cen($img, $node->{nid}, $up, $upp, $vp, $vpp,
			    $img->colorAllocate(@$xcol), 1);

			print PLANEFH "$$_x $$_y $$_z\n";
			printf MAPFH qq{<area href="#" alt="[nid %d]" shape="rect" } .
			    qq{onclick="selnode('%s', %d, %d, %d, %d, %d)" } .
			    qq{coords="%d, %d, %d, %d" />\n}, $node->{nid},
			    $names[$dim], $node->{nid}, $up, $vp, $upp, $vpp,
			    $up, $vp, $upp, $vpp;
		}
	}

	print MAPFH "</map>";

	local *OUTFH;
	open OUTFH, "> $fn" or err($fn);
	print OUTFH $img->png;
	close OUTFH;

	close PLANEFH;
	close MAPFH;
}

sub err {
	(my $progname = $0) =~ s!.*/!!;
	die("$progname: $!: " . join('', @_) . "\n");
}

sub parse_wimap {
	my ($max) = @_;

	@$max = (0, 0, 0);

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
		$max->[DIM_X] = $x if $x > $max->[DIM_X];
		$max->[DIM_Y] = $y if $y > $max->[DIM_Y];
		$max->[DIM_Z] = $z if $z > $max->[DIM_Z];
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

	my @keys = keys %jobs;
	my $len = scalar @keys;
	my $t = 0;
	foreach my $j (@keys) {
		$jobs{$j}{col} = col_get($t++, $len);
	}
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

sub write_jobfiles {
	my ($jobid, $job, $fn);
	local *F;

	$fn = _PATH_LEGEND;
	open F, "> $fn" or err($fn);
	print F <<EOF;
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_FREE] }]});"></div>
	Free<br />
	<div class="job" style="background-color: rgb(@{[join ',', @{ $statecol[ST_DOWN] }]});"></div>
	Disabled<br />
EOF

	while (($jobid, $job) = each %jobs) {
		# XXX: sanity check?
		$fn = subst(_PATH_JOB, id => $jobid);
		write_nodes($fn, $job->{nodes});

		my $col = join ',', @{ $job->{col} };
		print F <<HTML;
	<div class="job" style="background-color: rgb($col);"></div>
	Job $jobid<br />
HTML
	}

	close F;
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
