#!/usr/bin/perl -W
# $Id$

use lib qw(../lib);
use XTWMon;
use CGI;
use strict;
use warnings;

my $r = shift;
$r->content_type('text/plain');
my $cgi = CGI->new();
my $xtw = XTWMon->new(cgi => $cgi, flags => XCF_NOSID);

my %p;
$p{data} = $cgi->param("data");

if (jsdata_valid($p{data})) { # XXX: nothing to do with js
	my %data = (
		jobs	=> _PATH_JOB,
		nodes	=> _PATH_NODE,
		yods	=> _PATH_YOD,
	);

	my $pr_reg = $xtw->haspriv(PRIV_REG);
	my $pr_adm = $xtw->haspriv(PRIV_ADMIN);

	my $fn = $data{$p{data}};
	open F, "<", $fn or $xtw->err();
	$r->set_last_modified((stat $fn)[9]); # 9 = mtime
	while (<F>) {
		if ($p{data} eq "jobs") {
			/^(?:\d+)\s+(\w+)/ or next;

			unless ($pr_adm or $pr_reg &&
			    $cgi->remote_usr eq $1) {
				# 20257 devivo 270 81 37872 320 batch pkrnah16
				s{
					(\d+)	\s+	# job id	$1
					(?:.*?)	\s+	# owner
					(\d+)	\s+	# tmdur		$2
					(\d+)	\s+	# tmuse		$3
					(\d+)	\s+	# mem		$4
					(\d+)	\s+	# ncpus		$5
					(?:.*?)	\s+	# queue
					(?:.*)		# name
				}{
					join "\t", $1, "???", $2, $3,
					    $4, $5, "???", "???"
				}xe;
			}
		} elsif ($p{data} eq "yods") {
			unless ($pr_adm) {
				s{
					(\d+)	\s+	# yodid		$1
					(\d+)	\s+	# partid	$2
					(\d+)	\s+	# ncpus		$3
					(?:.*)		# cmd
				}{
					join "\t", $1, $2, $3, "???"
				}xe;
			}
		}
		print;
	}
	close F;
}
