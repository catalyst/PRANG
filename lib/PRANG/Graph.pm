
package PRANG::Graph;

use Moose::Role;

use PRANG::Graph::Context;

use PRANG::Graph::Node;
use PRANG::Graph::Class;
use PRANG::Graph::Element;
use PRANG::Graph::Text;
use PRANG::Graph::Seq;
use PRANG::Graph::Choice;
use PRANG::Graph::Quantity;

use PRANG::Graph::Meta::Attr;
use PRANG::Graph::Meta::Element;
use MooseX::Method::Signatures;

use MooseX::Attributes::Curried (
	has_attr => {
		metaclass => "PRANG::Attr",
	},
	has_element => {
		metaclass => "PRANG::Element",
	},
       );

requires 'xmlns';
requires 'root_element';

method marshaller($inv:) { #returns PRANG::Marshaller {
	if ( ref $inv ) {
		$inv = ref $inv;
	}
	PRANG::Marshaller->get( $inv );
}

method parse($class: Str $xml) {
	my $instance = $class->marshaller->parse($xml);
	return $instance;
}

method to_xml() {
	my $marshaller = $self->marshaller;
	$marshaller->to_xml($self);
}

1;

=head1 NAME

PRANG::Graph - XML mapping by peppering Moose attributes

=head1 SYNOPSIS

 package My::XML::Language;
 use Moose;
 with 'PRANG::Graph';
 sub xmlns {
    "some:urn";
 }

 method root_element( Str $name ) {
     # ... do something with $name ...
 }

 package main;

 # now for free!  Use PRANG::Marshaller to convert
 my $parsed = My::XML::Language->parse($xml);
 print $parsed->to_xml;

=head1 DESCRIPTION

PRANG::Graph allows you to mark attributes on your L<Moose> classes as
corresponding to XML attributes and child elements.  This allows your
class structure to function as an I<XML graph> (a generalized form of
an specification for the shape of an XML document; ie, what nodes and
attributes are allowed at which point).



=cut

