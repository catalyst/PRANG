
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

use PRANG::Marshaller;

use Moose::Exporter;
sub has_attr {
	my ( $meta, $name, %options ) = @_;
	$meta->add_attribute(
		$name,
		traits => ["PRANG::Attr"],
		%options,
	       );
}
sub has_element {
	my ( $meta, $name, %options ) = @_;
	$meta->add_attribute(
		$name,
		traits => ["PRANG::Element"],
		%options,
	       );
}

Moose::Exporter->setup_import_methods(
	with_meta => [ qw(has_attr has_element) ],
	metaclass_roles => [qw(PRANG::Graph::Meta::Class)],
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

 # declaring a /language/
 package My::XML::Language;
 use Moose;
 use PRANG::Graph;
 sub xmlns { "some:urn" }
 sub root_element { "Root" }
 with 'PRANG::Graph';
 has_element "data" =>
     is => "ro",
     isa => "My::XML::Language::Node",
     ;

 # declaring a /node/ in a language
 package My::XML::Language::Node;
 use Moose;
 use PRANG::Graph;
 has_attr "count" =>
     is => "ro",
     isa => "Num",
     ;
 has_element "text" =>
     is => "ro",
     isa => "Str",
     xml_nodeName => "",
     ;

 package main;
 # example document for the above.
 my $xml = q[<Root xmlns="some:urn"><data count="2">blah</data></Root>];

 # loading XML to data structures
 my $parsed = My::XML::Language->parse($xml);

 # converting back to XML
 print $parsed->to_xml;

=head1 DESCRIPTION

PRANG::Graph allows you to mark attributes on your L<Moose> classes as
corresponding to XML attributes and child elements.  This allows your
class structure to function as an I<XML graph> (a generalized form of
an specification for the shape of an XML document; ie, what nodes and
attributes are allowed at which point).

B<note:> this class applies a I<metarole>.  This means, that when you
C<use PRANG::Graph>, there is an implied;

  use Moose -traits => ["PRANG::Graph::Meta::Class"];

See L<PRANG::Graph::Meta::Class> for information on the super-powers
this instills in your metaclass.

However, the C<with 'PRANG::Graph';> part signifies something
different; it is not a I<metarole> but a regular role.  What it means
is that the class can be the I<root> of a document - which also means
it knows its own node name.  In general, a class does not have a
specific node name, allowing a particular schema type to be used for a
number of element names - W3C XML Schema is designed to work like
this.

=cut

