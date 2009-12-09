#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

{
	package Foo;
	use Moose;
	use PRANG::Graph;
	has_attr "lust" =>
		is => "ro",
		isa => "Str",
		xml_name => "envy",
		;
}

ok(Foo->meta->get_attribute("lust")->has_xml_name,
   "has_attr produces an XML attribute");

