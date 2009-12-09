
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
