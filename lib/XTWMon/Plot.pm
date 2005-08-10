#!/usr/bin/perl
# $Id$

package XTWMon::Plot;

use lib qw(..);
use XTWMon;
use CGI;
use IPC::Run;
use strict;
use warnings;

# Imporant files
use constant _PATH_GNUPLOT	=> "/usr/bin/gnuplot";
use constant _PATH_STDIN	=> "/dev/stdin";

use constant kTitle => "XT3 Wired View";

# Defaults to gnuplot
use constant kRotX => 60;
use constant kRotZ => 20;
use constant kScalX => 1;
use constant kScalZ => 1;

sub new {
	my ($class) = @_;
	my $pkg = ref($class) || $class;
	return bless {
		rx	=> kRotX,
		rz	=> kRotZ,
		sx	=> kScalX,
		sz	=> kScalZ,
		x	=> 0,
		y	=> 0,
		z	=> 0,
		jobs	=> []
	}, $pkg;
}

# Create a gnuplot file
sub gnu_plot {
	my ($obj) = @_;
	local (*IN, *OUT, *ERR);

	my $title = kTitle;

	my $h = IPC::Run::start([_PATH_GNUPLOT, _PATH_STDIN],
	    "<pipe", \*IN, ">pipe", \*OUT, "2>pipe", \*ERR)
	    or $obj->err(_PATH_GNUPLOT);
	print IN <<EOF;
set terminal png small color picsize 500 300
set view $obj->{rx}, $obj->{rz}, $obj->{sx}, $obj->{sz}
set xlabel "X"
set ylabel "Y"
set zlabel "Z"
set zrange [0:20]
set data style points
set pointsize 0.5
set lmargin 0
set bmargin 0
set tmargin 0
set tmargin 0
splot @{[$obj->file_list()]}
EOF
	close IN;
	print <OUT>, <ERR>;
	finish $h;
}

# create the list of files passed to gnuplot
sub file_list {
	my ($obj) = @_;

	my (@files, @labels);

	if (@{ $obj->{jobs} }) {
		# foreach $job $obj->{jobs}
		@files = glob(subst(_PATH_JOB, id => $obj->{jobs}[0]));
	} else {
		@files = glob(subst(_PATH_JOB, id => "*"));
	}
	@labels = map { 'job ' . join '', m{/(\d+)$} } @files;

	my ($x, $y, $z) = @$obj{qw(x y z)};
	$x = 0 unless -e subst(_PATH_DATA, dim => "x", pos => $x);
	$y = 0 unless -e subst(_PATH_DATA, dim => "y", pos => $y);
	$z = 0 unless -e subst(_PATH_DATA, dim => "z", pos => $z);

	push(@files, _PATH_FREE),     push(@labels, 'free')	if -e _PATH_FREE;
	push(@files, _PATH_DISABLED), push(@labels, 'disabled')	if -e _PATH_DISABLED;
	push(@files, subst(_PATH_DATA, dim => "x", pos => $x)),   push(@labels, "x-plane");
	push(@files, subst(_PATH_DATA, dim => "y", pos => $y)),   push(@labels, "y-plane");
	push(@files, subst(_PATH_DATA, dim => "z", pos => $z)),   push(@labels, "z-plane");

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

sub setjob {
	my ($obj, $id) = @_;
	push @{ $obj->{jobs} }, $id;
}

1;
