#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
	use_ok('Svsh') || print "Bail out Svsh!\n";
	use_ok('Svsh::Perp') || print "Bail out Svsh::Perp!\n";
	use_ok('Svsh::S6') || print "Bail out Svsh::S6!\n";
	use_ok('Svsh::Runit') || print "Bail out Svsh::Runit!\n";
}

diag("Testing Svsh $Svsh::VERSION, Perl $], $^X");
