#!/usr/bin/perl
#
# Script to create gnuplot of wired mode of XT3
#

use strict;
use warnings;

# Imporant Files
use constant kLayoutFile => "../src/data/rtrtrace";
use constant kGnuPlotFile => "../src/data/config.gp";
use constant kPngFile => "../src/data/gplot.png";
use constant kNidsListFile => "/home/torque/nids_list_phantom";
use constant kDisabledFile => "../src/data/disabled";
use constant kFreeFile => "../src/data/free";
use constant kJobPrefix => "../src/data/jid_";

use constant kTitle => "XT3 Wired View";

# XXX This should be read through sys.argv
use constant kRotX => "60";
use constant kRotZ => "20";
use constant kScalX => "1";
use constant kScalZ => "1";

my %gNid2Pos;
my %gJobList;
my $gDisabled = 1;
my $gFree = 0;

#############################
# Main

# Command Line Args
my $argc;
my @view = (kRotX, kRotZ, kScalX, kScalZ);
my $argnum;

$argc = $#ARGV + 1;

if($argc < 2)
{
	print "using default view\n";
}

foreach $argnum (0 .. $#ARGV)
{
	$view[$argnum] = $ARGV[$argnum];
}


# Parse files
parse_layout(kLayoutFile);
parse_nidslist(kNidsListFile);

# Run the plot
gnu_plot($view[0], $view[1], $view[2], $view[3]);

# Clear the data files
clear_files();

#
#############################

# Create a gnuplot file
sub gnu_plot
{
	my ($rx, $rz, $sx, $sz) = @_;

	open FP, ">".kGnuPlotFile;

	print FP "set output \"".kPngFile."\"\n";
	print FP "set term png\n";
	print FP "set view ".$rx.", ".$rz.", ".$sx.", ".$sz."\n";
	print FP "set xlabel \"X\"\n";
	print FP "set ylabel \"Y\"\n";
	print FP "set zlabel \"Z\"\n";
	print FP "set title \"".kTitle."\"\n";
	#print fp "set data style boxes\n";

	print FP "splot ".file_list()."\n";
	
	close FP ;
	
	system "gnuplot ".kGnuPlotFile;
}

# create the list of files that should be passed
# as arguments to gnuplot
sub file_list
{
	my $list = "";

	# string the files together
	for my $key (keys %gJobList)
	{
		$list .= "\'".$gJobList{$key}."\',";
	}

	chop $list;

	# Now add Disabled & Free Nodes if there were any
	if($gDisabled)
	{
		$list .= ",\'".kDisabledFile."\'";
	}

	if($gFree)
	{
		$list .=",\'".kFreeFile."\'";
	}
	
	return $list;
}

# delete the temporary files
sub clear_files
{
	my $jobfile;

	for my $key (keys %gJobList)
	{
		$jobfile = $gJobList{$key};
		unlink $jobfile;
	}

	unlink kDisabledFile;
	unlink kFreeFile;
}

# Obtain the (x,y,z) coordinates of every node
sub parse_layout
{
	my ($fin) = @_;

	open FP, $fin;

	while(<FP>)
	{
		chomp;
		my ($nid, $lay, $pos) = split;
		my ($x, $y, $z) = split(/,/, $pos);

		$gNid2Pos{$nid} = "$x $y $z";
	}

	close FP;
}
	
# parset the nidslist file and create a file
# for every jobid and add the node position
sub parse_nidslist
{
	my ($fin) = @_;

	open FP, $fin;

	while(<FP>)
	{
		chomp;
		my ($nid, $active, $jobid) = split;
		
		if ($jobid != 0)
		{
			# Active Job
			open FP2, ">>".kJobPrefix.$jobid;
			print FP2 $gNid2Pos{$nid}."\n";
			close FP2;

			# Store the filename (prefix not needed!
			# it is relative to the config file!!
			$gJobList{$jobid} = kJobPrefix.$jobid;
		}
		elsif($active == 0)
		{
			# Disabled Node
			open FP2, ">>".kDisabledFile;
			print FP2 $gNid2Pos{$nid}."\n";
			close FP2;

			# Flag that there are disabled nodes
			$gDisabled = 1;
		}
		else
		{
			# Free Node
			open FP2, ">>".kFreeFile;
			print FP2 $gNid2Pos{$nid}."\n";
			close FP2;

			# Flag that there are free nodes
			$gFree = 1;
		}

	}

	close FP;
}
