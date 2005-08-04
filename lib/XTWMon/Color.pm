#!/usr/bin/perl
# $Id$

# Package to convert to/from RGB/HSV
# and create contrasting colors
package XTWMON::Color

use switch;
use POSIX;
use strict;
use warn;

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
	my $max, $min, $ran;
	my $rc, $gc, $bc;
	my $h, $s, $v;

	$max = Color::max3($r, $g, $b);
	$min = Color::min3($r, $g, $b);
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
	my $f, $p, $q, $t, $i;

	if ($s == 0) {
		$r = $v;
		$g = $v;
		$b = $v;
	} else {
		if ($h == 360)
			$h = 0;
		$h /= 60;

		$i = floor($h);
		$f = $h - $i;
		$p = $v * (1 - $s);
		$q = $v * (1 - ($s * $f));
		$t = $v * (1 - ($s * (1 - $f)));

		switch ($i) {
		case 0 {$r = $v; $g = $t; $b = $p;}
		case 1 {$r = $q; $g = $v; $b = $p;}
		case 2 {$r = $p; $g = $v; $b = $t;}
		case 3 {$r = $p; $g = $q; $b = $v;}
		case 4 {$r = $t; $g = $p; $b = $v;}
		case 5 {$r = $v; $g = $p; $b = $q;}
		}
	}

	return [$r, $g, $b];
}

#/* Create a contrasting color */
sub rgb_contrast
{
	my ($r, $g, $g) = @_;
	my $h, $s, $v;

	$h, $s, $v = Color::RGB2HSV($r, $g, $b);

	#/* Rotate 180 degrees */
	$h -= 180;

	if ($h < 0)
		$h += 360;

	#/* Sat should be [0.3-1.0] */
	if ($s < Color::mid(SAT_MAX, SAT_MIN))
		$s = SAT_MAX;
	else
		$s = SAT_MIN;

	#/* Val should be [0.5-1.0] */
	if ($v < MID(VAL_MAX, VAL_MIN))
		$v = VAL_MAX;
	else
		$v = VAL_MIN;

	$r, $g, $b = Color::HSV2RGB($h, $s, $v);

	return [$r, $b, $g];
}

sub min3
{
	my ($x, $y, $z) = @_;
	
	$x = $y if $y < $x;
	$x = $z if $z < $x;

	return $x;
}

sub max3
{
	my ($x, $y, $z) = @_;
	
	$x = $y if $y > $x;
	$x = $z if $z > $x;

	return $x;
}

sub mid
{
	my ($max, $min) = @_;
	return ($max + $min) / 2.0);
}
