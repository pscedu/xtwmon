#!/usr/bin/perl -W
# $Id$

use lib qw(../lib);
use XTWMon;
use CGI;
use strict;
use warnings;

my $r = shift;
$r->content_type('text/javascript');
my $cgi = CGI->new();
my $xtw = XTWMon->new(cgi => $cgi, flags => XCF_REQSID);

my %p;
$p{jsdata} = $cgi->param("data");

if (jsdata_valid($p{jsdata})) {
	my %jsdata = (
		jobs	=> _GP_JOBJS,
		nodes	=> _GP_NODEJS,
		yods	=> _GP_YODJS,
	);

	my $pr_reg = $xtw->haspriv(PRIV_REG);
	my $pr_adm = $xtw->haspriv(PRIV_ADMIN);

	my $fn = $xtw->dynpath($jsdata{$p{jsdata}});
	open JS, "<", $fn or $xtw->err();
	my $ok = 0;
	my $jfilter = "name|queue";
	while (<JS>) {
		if ($p{jsdata} eq "jobs") {
			if (/^\tj = new Job/) {
				$ok = 0;
			} elsif (/^\tj\.owner = '(\w+)'/) {
				$ok = ($pr_adm or ($pr_reg &&
				    $cgi->remote_user eq $1));
				next unless $ok;
			} elsif (/^\tj\.(?:$jfilter) = /) {
				next unless $ok;
			}
		} elsif ($p{jsdata} eq "yods") {
			if (/^\ty\.cmd = /) {
				next unless $pr_adm;
			}
		}
		print;
	}
	close JS;
}
