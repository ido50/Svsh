#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok('Pye') || print "Bail out!\n";
}

diag("Testing Pye $Pye::VERSION, Perl $], $^X");
