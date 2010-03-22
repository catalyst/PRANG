
package PRANG::Graph::Text;

use Moose;
use MooseX::Method::Signatures;
use XML::LibXML;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	;

method node_ok( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	return ( $node->nodeType == XML_TEXT_NODE or
			 $node->nodeType == XML_CDATA_SECTION_NODE );
}

method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	if ( $node->nodeType == XML_TEXT_NODE ) {
		($self->attrName, $node->data);
	}
	elsif ( $node->nodeType == XML_CDATA_SECTION_NODE ) {
		($self->attrName, $node->data);
	}
	else {
		$ctx->exception("expected text node", $node);
	}
}

method complete( PRANG::Graph::Context $ctx ) {
	1;
}

method expected( PRANG::Graph::Context $ctx ) {
	"TextNode";
}

method output ( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx, Item $value?, Int $slot?, Str $name? ) {
	$value //= do {
		my $attrName = $self->attrName;
		$item->$attrName;
	};
	if ( ref $value ) {
		$value = $value->[$slot];
	}
	my $doc = $node->ownerDocument;
	my $tn = $doc->createTextNode($value);
	$node->appendChild($tn);
}

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Text - accept an XML TextNode

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point may contain
a text node.  If it doesn't, this is considered equivalent to a
zero-length text node.

If the element only has only complex children, it will not have one of
these objects in its graph.

Along with L<PRANG::Graph::Element>, this graph node is the only type
which may actually consume input XML nodes or emit them on output.
The other node types merely change the state in the
L<PRANG::Graph::Context> object.

=head1 ATTRIBUTES

=over

=item B<attrName>

Used when emitting; specifies the method to call to retrieve the item
to be output.  Also used when parsing, to return the Moose attribute
slot for construction.

=back

=head1 SEE ALSO

L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element>,
L<PRANG::Graph::Context>, L<PRANG::Graph::Node>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

