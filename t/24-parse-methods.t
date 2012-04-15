#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

use lib "t";

use Octothorpe;
use XMLTests;

my @eg_filenames = map {"t/$_"}
	sort {$a cmp $b} XMLTests::find_tests("xml/valid");

my $valid_foo = Octothorpe->parse_file( shift @eg_filenames );
ok($valid_foo, "parse_file('filename')");

open FH, "<", shift @eg_filenames;
$valid_foo = Octothorpe->parse_fh( \*FH );
ok($valid_foo, "parse_fh(\*FOO)");

eval {Octothorpe->parse_fh( 'blah' )};
like($@, qr{Parameter #1 \("blah"\) to PRANG::Graph::parse_fh did not pass the 'checking type constraint for GlobRef' callback}, 
    "parse_fh parameter validated"); 