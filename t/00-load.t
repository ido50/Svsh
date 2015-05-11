#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok('Svsh') || print "Bail out!\n";
}

diag("Testing Svsh $Svsh::VERSION, Perl $], $^X");
