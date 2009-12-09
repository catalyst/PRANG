#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

{
	package Lust;
	use Moose;
	use PRANG::Graph;
	has_attr "envy" =>
		is => "ro",
		isa => "Str",
		xml_name => "greed",
		;
	sub xmlns {}
	with "PRANG::Graph::Class";
}

ok(Lust->meta->get_attribute("envy")->has_xml_name,
   "has_attr produces an XML attribute");

{
	package Octothorpe;
	use Moose;
	use PRANG::Graph;
	has_element "hyphen" =>
		is => "ro",
		isa => "Bool",
		xml_nodeName => "emdash",
		;
	has_element "colon" =>
		is => "ro",
		isa => "Str",
		;
	has_element "interpunct" =>
		is => "ro",
		isa => "Int",
		predicate => "has_interpunct",
		;
	has_element "apostrophe" =>
		is => "ro",
		isa => "Octothorpe",
		;
	has_element "solidus" =>
		is => "ro",
		isa => "Octothorpe|Int",
		xml_nodeName => {
			"braces" => "Int",
			"parens" => "Octothorpe",
		},
		;
	has_element "bullet" =>
		is => "ro",
		isa => "ArrayRef[Str|Int]",
		xml_max => 5,
		xml_nodeName => {
			"umlout" => "Int",
			"guillemets" => "Str",
		},
		;
	has_element "backslash" =>
		is => "ro",
		isa => "ArrayRef[Octothorpe]",
		;
	has_element "asterism" =>
		is => "ro",
		isa => "ArrayRef[Octothorpe|Lust|Str]",
		xml_nodeName => {
			"space" => "Octothorpe",
			"underscore" => "Lust",
			"slash" => "Str",
		},
		;
	sub xmlns {}
	with "PRANG::Graph::Class";
}

my %atts = map { $_->name => $_ } Octothorpe->meta->get_all_attributes;
my @attnames = map { $_->name }
	sort { $a->insertion_order <=> $b->insertion_order }
	values %atts;
my %gn;

for my $attname (@attnames) {
	my $gn = eval { $atts{$attname}->graph_node };
	if ( !$gn ) {
		if ( $@ ) {
			diag("error during build of '$attname' graph node: $@");
		}
	}
	ok($gn, "Build graph node for '$attname' attribute ("
		   .($atts{$attname}->type_constraint));
	$gn{$attname} = $gn;
}


