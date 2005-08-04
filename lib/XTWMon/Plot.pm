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

# Must be absolute, since mod_perl puts you in strange places.
use constant _PATH_DISABLED	=> "/var/www/html/xtwmon/src/data/disabled";
use constant _PATH_FREE		=> "/var/www/html/xtwmon/src/data/free";
use constant _PATH_JOBPREFIX	=> "/var/www/html/xtwmon/src/data/jid_";

use constant kTitle => "XT3 Wired View";

# Defaults to gnuplot
use constant kRotX => 60;
use constant kRotZ => 20;
use constant kScalX => 1;
use constant kScalZ => 1;

sub new {
	my ($class, $r) = @_;
	my $pkg = ref($class) || $class;
	return bless {
		r	=> $r,
	}, $pkg;
}

# Create a gnuplot file
sub gnu_plot {
	my ($obj, $rx, $rz, $sx, $sz) = @_;
	local (*IN, *OUT, *ERR);

	my $title = kTitle;

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
	my @files = glob(_PATH_JOBPREFIX . "*");
	push @files, _PATH_FREE		if -e _PATH_FREE;
	push @files, _PATH_DISABLED	if -e _PATH_DISABLED;
	return ("'" . join("','", @files) . "'");
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

	# Run the plot
	$obj->gnu_plot($rx, $rz, $sx, $sz);
}

1;
