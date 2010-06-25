#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use inc::Module::Install;

name            ("PRANG");
abstract        ("Moose XML Processor");
author          ("Catalyst SRS Team <team-srs\@catalyst.net.nz>");
version_from     "lib/PRANG.pm";
license         ('artistic');
no_index	directory => 'doc';

requires        ("perl" => 5.010);
requires        ("Moose" => 0.92);
requires        ("Set::Object" => 1.09);
requires        ("XML::LibXML" => 1.65);
requires        ("MooseX::Method::Signatures" => 0.17);

my @test_requires = (
	"XML::Compare" => 0.02,
	"Scriptalicious" => 1.16,
	"YAML" => 0,
	);
while (my ($module, $version) = splice @test_requires, 0, 2) {
	test_requires($module => $version);
	include($module => $version);
}

&WriteAll;
