#!/usr/bin/env perl

use Test::More tests => 5;

use ok('Svsh');
use ok('Svsh::Perp');
use ok('Svsh::S6');
use ok('Svsh::Runit');
use ok('Svsh::Daemontools');

diag("Testing Svsh $Svsh::VERSION, Perl $], $^X");
