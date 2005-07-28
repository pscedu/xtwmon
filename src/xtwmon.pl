#!/usr/bin/perl
# $Id$

use GD;
use POSIX;

use strict;
use warnings;

use constant _PATH_WIMAP => "data/rtrtrace";
use constant _PATH_JOBMAP => "data/nids_list_phantom";

use constant IMG_WIDTH => 600;
use constant IMG_HEIGHT => 400;

use constant DIM_X => 0;
use constant DIM_Y => 1;
use constant DIM_Z => 2;

use constant SLEEP_INTV => 5000;

use constant ST_MTIME => 9;

my $out_dir = "../www/latest";
my $archive_tmpl = "../www/data-%Y-%m-%d-tm-%H-%M";

my %dimcol = (
	DIM_X() => "red",
	DIM_Y() => "green",
	DIM_Z() => "blue"
);

# end config

my @max;
my @nodes;
my @invmap;

parse_wimap(\@max, \@nodes);

for (;;) {
	if (-d $out_dir) {
		my $ts = (stat $out_dir)[ST_MTIME];
		my $dst = strftime($archive_tmpl, localtime $ts);
		rename($out_dir, $dst) || err("rename: $out_dir to $dst");
	}
	mkdir $out_dir, 0755 || err("mkdir: $out_dir");

	parse_jobmap();

	my $t;

	for $t (0 .. $max[DIM_X]) {
		gen(DIM_X, $t, "$out_dir/x$t.png")
	}

	for $t (0 .. $max[DIM_Y]) {
		gen(DIM_Y, $t, "$out_dir/y$t.png")
	}

	for $t (0 .. $max[DIM_Z]) {
		gen(DIM_Z, $t, "$out_dir/z$t.png")
	}

exit;
	sleep(SLEEP_INTV);
}

sub cen {
	my ($img, $str, $sx, $ex, $y, $col) = @_;
	my $len = length($str);
#	$img->string($fn, ($sx + $ex) / 2 - $fn->width * $len / 2,
#	    $y + $fn->height, $str, $col);
	my $d_img = GD::Image->new(100, 100);
	my $fn = "/usr/X11R6/lib/X11/fonts/TTF/tahoma.ttf";
	my @bnd = $d_img->stringFT($col, $fn, 10, 0, 0, 50, $str);
	my $ren_w = $bnd[2] - $bnd[0];
	my $ren_h = $bnd[1] - $bnd[7];
	$img->stringFT($col, $fn, 10, 0,
	    ($sx + $ex) / 2 - $ren_w / 2, $y + $ren_h, $str);
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
		"blue"	=> $img->colorAllocate(0, 0, 255)
	);

	my @labels = (
		"YZ Plane at X=$pos",
		"XZ Plane at Y=$pos",
		"XY Plane at Z=$pos"
	);

	my @xdim = (
		[ DIM_Z, DIM_Y ],
		[ DIM_X, DIM_Z ],
		[ DIM_X, DIM_Y ]
	);

	$img->fill(1, 1, $col_white);
	my ($used_w, $used_h) = cen($img, $labels[$dim], 0, IMG_WIDTH,
	    0, $col_black);
	$used_h += 2; # Text border

	my ($udim, $vdim) = @{ $xdim[$dim] };

	my $uincr = IMG_WIDTH / $max[$udim];
	my $vincr = (IMG_HEIGHT - $used_h) / $max[$vdim];
	my $node_w = $uincr - 10;
	my $node_h = $vincr - 10;

	my ($u, $up, $v, $vp);
	for ($u = 0, $up = 0; $u < $max[$udim]; $u++, $up += $uincr) {
		for ($v = 0, $vp = $used_h; $v < $max[$vdim]; $v++, $vp += $vincr) {
			$img->filledRectangle($up, $vp,
			    $up + $node_w, $vp + $node_h, $col{$dimcol{$dim}});
			$img->rectangle($up, $vp,
			    $up + $node_w, $vp + $node_h, $col_black);
		}
	}

	local *OUTFN;
	open OUTFN, "> $fn" or err($fn);
	print OUTFN $img->png;
	close OUTFN;
}

sub err {
	(my $progname = $0) =~ s!.*/!!;
	die("$progname: $!: " . join('', @_) . "\n");
}

sub parse_wimap {
	my ($max, $nodes) = @_;

	$nodes = [];
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

		$nodes->[$x] = [] unless ref $nodes->[$x] eq "ARRAY";
		$nodes->[$x][$y] = [] unless ref $nodes->[$x][$y] eq "ARRAY";
		$invmap[$nid] = $nodes->[$x][$y][$z] = {
			nid => $nid
		};

		$max->[DIM_X] = $x if $x > $max->[DIM_X];
		$max->[DIM_Y] = $y if $y > $max->[DIM_Y];
		$max->[DIM_Z] = $z if $z > $max->[DIM_Z];
	}
	close WIMAP;
}

my @jobs;

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
		$invmap[$nid]{job} = job_get($jobid);
	}
	close JMAP;

	for (my $j = 0; $j < @jobs; $j++) {
		$jobs[$j]{col} = col_get($j, scalar @jobs);
	}
}

sub job_get {
	my ($jobid) = shift;
	return $jobs[$jobid] if $jobs[$jobid];
	$jobs[$jobid] = {
		id => $jobid,
	};
}

sub col_get {
	my ($pos, $tot) = @_;
	return [$pos/$tot*255, $pos/$tot*255, $pos/$tot*255];
}
