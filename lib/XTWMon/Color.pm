#!/usr/bin/perl
# $Id$

# Package to convert to/from RGB/HSV
# and create contrasting colors
package XTWMon::Color;

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

sub RGB2HSV {
	my ($r, $g, $b) = @_;
	my ($max, $min, $ran);
	my ($rc, $gc, $bc);
	my ($h, $s, $v);

	$r /= 255;
	$g /= 255;
	$b /= 255;

	$max = max($r, $g, $b);
	$min = min($r, $g, $b);
	$ran = $max - $min;

	$h = 0;
	$s = 0;

	# Value
	$v = $max;

	# Saturation
	$s = $ran / $max if $max;

	# Hue
	if ($s != 0) {
		# Measure color distances
		$rc = ($max - $r) / $ran;
		$gc = ($max - $g) / $ran;
		$bc = ($max - $b) / $ran;

		if ($r == $max) {
			# Between yellow and magenta
			$h = $bc - $gc;
		} elsif ($g == $max) {
			# Between cyan and yellow
			$h = 2 + $rc - $bc;
		} elsif ($b == $max) {
			# Between magenta and cyan
			$h = 4 + $gc - $rc;
		}

		# Convert to degrees
		$h *= 60;
		$h += 360 if $h < 0;
	}

	return [$h, $s, $v];
}


sub HSV2RGB {
	my ($h, $s, $v) = @_;
	my ($f, $p, $q, $t, $i);
	my ($r, $g, $b);

	if ($s == 0) {
		$r = $v;
		$g = $v;
		$b = $v;
	} else {
		$h = 0 if $h == 360;
		$h /= 60;

		$i = int($h);

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

	return [int $r * 255, int $g * 255, int $b * 255];
}

# Create a contrasting color
use constant ROT_DEG => 45;

use constant SAT_SHIFT => 0.2;

use constant CON_VAL_MAX => 0.85 * VAL_MAX;
use constant CON_VAL_MIN => 0.4 * VAL_MIN;

use constant CON_SAT_MAX => 0.6 * SAT_MAX;
use constant CON_SAT_MIN => SAT_MIN;

sub rgb_contrast {
	my ($r, $g, $b) = @_;

	my ($h, $s, $v) = @{ RGB2HSV($r, $g, $b) };

	# Rotate 180 degrees
	$h -= ROT_DEG;
	$h += 360 if $h < 0;

	# Saturation
=cut
	if ($s < CON_SAT_MAX) {
		$s = SAT_MAX;
	} else {
		$s = CON_SAT_MIN;
	}
=cut
#	$s = CON_SAT_MIN if($s > CON_SAT_MAX);

=cut
	$s += SAT_SHIFT;
	$s = 1.0 if $s > 1.0;
=cut

	# Value (Brightness)
	if ($v < CON_VAL_MAX) {
		$v = VAL_MAX;
	} else {
		$v = CON_VAL_MIN;
	}

	return HSV2RGB($h, $s, $v);
}

sub min {
	my $min = shift;
	foreach (@_) {
		$min = $_ if $_ < $min;
	}
	return $min;
}

sub max {
	my $max = shift;
	foreach (@_) {
		$max = $_ if $_ > $max;
	}
	return $max;
}

sub mid {
	my ($max, $min) = @_;
	return (($max + $min) / 2);
}

1;
