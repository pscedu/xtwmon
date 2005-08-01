#!/usr/bin/perl
# $Id$

# Script to create gnuplot of wired mode of XT3

use CGI;
use strict;
use warnings;

# Imporant files
use constant kLayoutFile	=> "../src/data/rtrtrace";
use constant kNidsListFile	=> "../src/data/nids_list_phantom";

use constant kGnuPlotFile	=> "../src/data/config.gp";
use constant kPngFile		=> "../src/data/gplot.png";
use constant kDisabledFile	=> "../src/data/disabled";
use constant kFreeFile		=> "../src/data/free";
use constant kJobPrefix		=> "../src/data/jid_";

use constant kTitle => "XT3 Wired View";

# XXX This should be read through sys.argv
use constant kRotX => "60";
use constant kRotZ => "20";
use constant kScalX => "1";
use constant kScalZ => "1";

my @gNid2Pos;
my @gJobList;
my $gDisabled = 1;
my $gFree = 0;

#############################
# Main

my ($rx, $rz, $sx, $sz) = (kRotX, kRotZ, kScalX, kScalZ);

if (@ARGV == 4) {
	$rx = $ARGV[0] if $ARGV[0] =~ /^\d+$/;
	$rz = $ARGV[1] if $ARGV[1] =~ /^\d+$/;
	$sx = $ARGV[2] if $ARGV[2] =~ /^\d+$/;
	$sz = $ARGV[3] if $ARGV[3] =~ /^\d+$/;
}

# Parse files
parse_layout(kLayoutFile);
parse_nidslist(kNidsListFile);

# Run the plot
gnu_plot($rx, $rz, $sx, $sz);

# Clear the data files
clear_files();

#
#############################

# Create a gnuplot file
sub gnu_plot {
	my ($rx, $rz, $sx, $sz) = @_;

	local $/ = "\n";

	my $file = kPngFile;
	my $title = kTitle;
	open FP, "> " . kGnuPlotFile or err(kGnuPlotFile);
	print FP <<EOF;
set output "$file"
set term png
set view $rx, $rz, $sx, $sz
set xlabel "X"
set ylabel "Y"
set zlabel "Z"
set title "$title"
set data style boxes
splot @{[file_list()]}
EOF
	close FP;

	system "gnuplot " . kGnuPlotFile;
}

# create the list of files that should be passed
# as arguments to gnuplot
sub file_list {
	my $list = "";

	# string the files together
	foreach my $file (@gJobList) {
		$list .= "'$file',";
	}

	chop $list;

	# Now add disabled & free nodes if there were any
	$list .= ",'" . kDisabledFile . "'" if $gDisabled;
	$list .= ",'" . kFreeFile . "'" if $gFree;

	return $list;
}

# delete the temporary files
sub clear_files {
	foreach my $file (@gJobList) {
		unlink $file;
	}

	unlink kDisabledFile if $gDisabled;
	unlink kFreeFile if $gFree;
}

# Obtain the (x,y,z) coordinates of every node
sub parse_layout {
	my ($fin) = @_;

	open FP, $fin or err($fin);
	while (<FP>) {
		chomp;
		my ($nid, $lay, $pos) = split;
		my ($x, $y, $z) = split(/,/, $pos);

		$gNid2Pos[$nid] = "$x $y $z";
	}
	close FP;
}

# parset the nidslist file and create a file
# for every jobid and add the node position
sub parse_nidslist {
	my ($fin) = @_;

	local $_;
	open FP, $fin or err($fin);
	while (<FP>) {
		chomp;
		my ($nid, $active, $jobid) = split;

		if ($jobid != 0) {
			# Active job
			open FP2, ">> " . kJobPrefix . $jobid;
			print FP2 "$gNid2Pos[$nid]\n";
			close FP2;

			# Store the filename (prefix not needed)
			# It is relative to the config file
			$gJobList[$jobid] = kJobPrefix . $jobid;
		} elsif ($active == 0) {
			# Disabled node
			open FP2, ">> " . kDisabledFile or err(kDisabledFile);
			print FP2 "$gNid2Pos[$nid]\n";
			close FP2;

			# Flag that there are disabled nodes
			$gDisabled = 1;
		} else {
			# Free Node
			open FP2, ">> " . kFreeFile or err(kFreeFile);
			print FP2 "$gNid2Pos[$nid]\n";
			close FP2;

			# Flag that there are free nodes
			$gFree = 1;
		}
	}
	close FP;
}

sub err {
	(my $progname = $0) =~ s!.*/!!;
	warn "$progname: ", @_, ": $!\n";
	exit 1;
}
