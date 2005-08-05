#!/usr/bin/perl
# $Id$

# Package to convert to/from RGB/HSV
# and create contrasting colors
package XTWMon::Color;

use POSIX;
use Exporter;

use strict;
use warnings;

our @ISA = qw(Exporter);

our @EXPORT = qw(HUE_MIN SAT_MIN HUE_MAX SAT_MAX VAL_MIN VAL_MAX);

# Constants
use constant HUE_MIN => 0.0;
use constant HUE_MAX => 360.0;
use constant SAT_MIN => 0.3;
use constant SAT_MAX => 1.0;
use constant VAL_MIN => 0.5;
use constant VAL_MAX => 1.0;

# The following two mathematical algorithms were created from
# pseudocode found in "Fundamentals of Interactive Computer Graphics".

sub RGB2HSV
{
	my ($r, $g, $b) = @_;
	my ($max, $min, $ran);
	my ($rc, $gc, $bc);
	my ($h, $s, $v);

	$max = max($r, $g, $b);
	$min = min($r, $g, $b);
	$ran = $max - $min;

	$h = 0;
	$s = 0;

	#/* Value */
	$v = $max;

	#/* Saturation */
	$s = $ran / $max if ($max != 0);

	#/* Hue */
	if ($s != 0) {

		#/* Measure color distances */
		$rc = ($max - $r) / $ran;
		$gc = ($max - $g) / $ran;
		$bc = ($max - $b) / $ran;

		#/* Between yellow and magenta */
		if ($r == $max) {
			$h = $bc - $gc;
		}
		#/* Between cyan and yellow */
		elsif ($g == $max) {
			$h = 2 + $rc - $bc;
		}
		#/* Between magenta and cyan */
		elsif ($b == $max) {
			$h = 4 + $gc - $rc;
		}

		#/* Convert to degrees */
		$h *= 60;

		if ($h < 0) {
			$h += 360;
		}
	}

	return [$h, $s, $v];
}


sub HSV2RGB
{
	my ($s, $h, $v) = @_;
	my ($f, $p, $q, $t, $i);
	my ($r, $g, $b);

	if ($s == 0) {
		$r = $v;
		$g = $v;
		$b = $v;
	} else {
		$h = 0 if $h == 360;
		$h /= 60;

		$i = floor($h);
		$f = $h - $i;
		$p = $v * (1 - $s);
		$q = $v * (1 - ($s * $f));
		$t = $v * (1 - ($s * (1 - $f)));

		$r = $v, $g = $t, $b = $p if $i == 0;
		$r = $q, $g = $v, $b = $p if $i == 1;
		$r = $p, $g = $v, $b = $t if $i == 2;
		$r = $p, $g = $q, $b = $v if $i == 3;
		$r = $t, $g = $p, $b = $v if $i == 4;
		$r = $v, $g = $p, $b = $q if $i == 5;
	}

	return [$r, $g, $b];
}

#/* Create a contrasting color */
sub rgb_contrast
{
	my ($r, $g, $b) = @_;
	my ($h, $s, $v);

	($h, $s, $v) = RGB2HSV($r, $g, $b);

	#/* Rotate 180 degrees */
	$h -= 180;
	$h += 360 if $h < 0;

	#/* Sat should be [0.3-1.0] */
	if ($s < mid(SAT_MAX, SAT_MIN)){
		$s = SAT_MAX;
	} else {
		$s = SAT_MIN;
	}

	#/* Val should be [0.5-1.0] */
	if ($v < MID(VAL_MAX, VAL_MIN)) {
		$v = VAL_MAX;
	} else {
		$v = VAL_MIN;
	}

	($r, $g, $b) = HSV2RGB($h, $s, $v);

	return [$r, $b, $g];
}

sub min
{
	my $min = shift;
	foreach (@_) {
		$min = $_ if $_ < $min;
	}
	return $min;
}

sub max
{
	my $max = shift;
	foreach (@_) {
		$max = $_ if $_ > $max;
	}
	return $max;
}

sub mid
{
	my ($max, $min) = @_;
	return (($max + $min) / 2.0);
}

1;
