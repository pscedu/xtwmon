#!/usr/bin/perl
# $Id$

package XTWMon::Plot;

use CGI;
use IPC::Run;
use strict;
use warnings;

# Imporant files
use constant _PATH_GNUPLOT	=> "/usr/bin/gnuplot";
use constant _PATH_STDIN	=> "/dev/stdin";
use constant kLayoutFile	=> "/var/www/html/xtwmon/src/data/rtrtrace";
use constant kNidsListFile	=> "/var/www/html/xtwmon/src/data/nids_list_phantom";

use constant kGnuPlotFile	=> "/tmp/config.gp";
use constant kDisabledFile	=> "/tmp/disabled";
use constant kFreeFile		=> "/tmp/free";
use constant kJobPrefix		=> "/tmp/jid_";

use constant kTitle => "XT3 Wired View";

# XXX This should be read through sys.argv
use constant kRotX => 60;
use constant kRotZ => 20;
use constant kScalX => 1;
use constant kScalZ => 1;

sub new {
	my ($class, $r) = @_;
	my $pkg = ref($class) || $class;
	return bless {
		r	=> $r,
		nodes	=> [],
		jobs	=> {},
		dis	=> 1,
		free	=> 0,
	}, $pkg;
}

# Create a gnuplot file
sub gnu_plot {
	my ($obj, $rx, $rz, $sx, $sz) = @_;

	my $title = kTitle;

	local (*IN, *OUT, *ERR);

	# Hack: programs are not allowed to write to
	# their stdout, but stderr works fine, so
	# redirect to there.
	my $h = IPC::Run::start([_PATH_GNUPLOT, _PATH_STDIN],
	    "<pipe", \*IN, ">pipe", \*OUT, "2>pipe", \*ERR)
	    or $obj->err(_PATH_GNUPLOT);
	print IN <<EOF;
set terminal png small color picsize 500 300
set view $rx, $rz, $sx, $sz
set xlabel "X"
set ylabel "Y"
set zlabel "Z"
set zrange [0:20]
set title "$title"
set data style points
set pointsize 0.5
splot @{[$obj->file_list()]}
EOF
	close IN;
	print <OUT>, <ERR>;
	finish $h;
}

# create the list of files that should be passed
# as arguments to gnuplot
sub file_list {
	my ($obj) = @_;

	# string the files together
	my $list = "'" . join("','", values %{ $obj->{jobs} }) . "'";

	# Now add disabled & free nodes if there were any
	$list .= ",'" . kDisabledFile . "'"	if $obj->{dis};
	$list .= ",'" . kFreeFile . "'"		if $obj->{free};
	return $list;
}

# delete the temporary files
sub clear_files {
	my ($obj) = @_;

	unlink $_ foreach (values %{ $obj->{jobs} });

	unlink kDisabledFile	if $obj->{dis};
	unlink kFreeFile	if $obj->{free};
}

# Obtain the (x,y,z) coordinates of every node
sub parse_layout {
	my ($obj, $fin) = @_;

	local $_;
	open FP, $fin or $obj->err($fin);
	while (<FP>) {
		chomp;
		my ($nid, $lay, $pos) = split;
		my ($x, $y, $z) = split(/,/, $pos);

		$obj->{nodes}[$nid] = "$x $y $z";
	}
	close FP;
}

# parse the nidslist file and create a file
# for every jobid and add the node position
sub parse_nidslist {
	my ($obj, $fin) = @_;

	my $fn;
	local $_;
	open FP, $fin or $obj->err($fin);
	while (<FP>) {
		chomp;
		my ($nid, $active, $jobid) = split;

		if ($jobid != 0) {
			# Active job
			$fn = kJobPrefix . $jobid;

			# Store the filename (prefix not needed)
			# It is relative to the config file
			$obj->{jobs}{$jobid} = $fn;
		} elsif ($active == 0) {
			# Disabled node
			$fn = kDisabledFile;
			$obj->{dis} = 1;
		} else {
			# Free Node
			$fn = kFreeFile;
			$obj->{free} = 1;
		}
		open FP2, ">> $fn" or err($fn);
		print FP2 "$obj->{nodes}[$nid]\n";
		close FP2;
	}
	close FP;
}

sub err {
	shift;
	(my $progname = $0) =~ s!.*/!!;
	warn "$progname: ", @_, ": $!\n";
	exit 1;
}

sub main {
	my ($obj) = shift;

	$obj->{r}->content_type('image/png');
	my ($rx, $rz, $sx, $sz) = (kRotX, kRotZ, kScalX, kScalZ);

	# Parse files
	$obj->parse_layout(kLayoutFile);
	$obj->parse_nidslist(kNidsListFile);

	# Run the plot
	$obj->gnu_plot($rx, $rz, $sx, $sz);

	# Clear the data files
#	$obj->clear_files();
}

1;
