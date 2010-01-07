#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use t::Octothorpe;

ok(Fingernails->meta->get_attribute("currency")->has_xml_name,
   "has_attr produces an XML attribute");

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
		   .($atts{$attname}->type_constraint).")");
	$gn{$attname} = $gn;
}

ok(Octothorpe->meta->meta->does_role("PRANG::Graph::Meta::Class"),
   "use PRANG::Graph applies metarole");
