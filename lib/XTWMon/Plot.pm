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
use constant _PATH_DISABLED	=> "/var/www/html/xtwmon/www/latest/disabled";
use constant _PATH_FREE		=> "/var/www/html/xtwmon/www/latest/free";
use constant _PATH_JOBPREFIX	=> "/var/www/html/xtwmon/www/latest/jid_";

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
		rx	=> kRotX,
		rz	=> kRotZ,
		sx	=> kScalX,
		sz	=> kScalZ,
		x	=> 0,
		y	=> 0,
		z	=> 0
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
	my @labels = map { 'job ' . join '', /jid_(\d+)$/ } @files;
	push(@files, _PATH_FREE),     push @labels, 'free'	if -e _PATH_FREE;
	push(@files, _PATH_DISABLED), push @labels, 'disabled' if -e _PATH_DISABLED;
	my $files = "";
	my $n;
	for ($n = 0; $n < @files; $n++) {
		$files .= qq{'$files[$n]' title '$labels[$n]', };
	}
	$files =~ s/, $//;
	return ($files);
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
	$obj->gnu_plot();
}

sub setview {
	my ($obj, $rx, $rz, $sx, $sz) = @_;
	$obj->{rx} = $rx if defined $rx && $rx =~ /^\d+$/;
	$obj->{rz} = $rz if defined $rz && $rz =~ /^\d+$/;
	$obj->{sx} = $sx if defined $sx && $sx =~ /^\d+$/;
	$obj->{sz} = $sz if defined $sz && $sz =~ /^\d+$/;
}

sub setpos {
	my ($obj, $x, $y, $z) = @_;
	$obj->{x} = $x if defined $x && $x =~ /^\d+$/;
	$obj->{y} = $y if defined $y && $y =~ /^\d+$/;
	$obj->{z} = $z if defined $z && $z =~ /^\d+$/;
}

1;
