
package PRANG::Graph::Element;

use 5.010;
use Moose;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;
use XML::LibXML;

BEGIN {
	class_type "XML::LibXML::Node";
	class_type "XML::LibXML::Element";
}

has 'xmlns' =>
	is => "ro",
	isa => "Str",
	predicate => "has_xmlns",
	;

has 'nodeName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'nodeClass' =>
	is => "ro",
	isa => "Str",
	predicate => "has_nodeClass",
	;

has 'nodeName_attr' =>
	is => "rw",
	isa => "Str",
	predicate => "has_nodeName_attr",
	;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'contents' =>
	is => "rw",
	isa => "PRANG::Graph::Node",
	predicate => "has_contents",
	;

method node_ok( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	return unless $node->nodeType == XML_ELEMENT_NODE;
	if ( ($node->prefix||"") ne ($ctx->prefix||"") ) {
		my $got_xmlns = ($ctx->xsi->{$node->prefix||""}||"");
		my $wanted_xmlns = ($self->xmlns||"");
		if ( $wanted_xmlns ne "*" and
			     $got_xmlns ne $wanted_xmlns ) {
			$ctx->exception("invalid XML namespace", $node, 1);
		}
	}
	# this is bad for processContents=skip + namespace="##other"
	my $ret_nodeName = $self->nodeName eq "*" ?
		$node->localname : "";
	if ( !$ret_nodeName and $node->localname ne $self->nodeName ) {
		return;
	}
	else {
		return $ret_nodeName;
	}
}

method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	my $ret_nodeName;
	if ( !defined ($ret_nodeName = $self->node_ok($node, $ctx)) ) {
		$ctx->exception(
		"invalid element; expected '".$self->nodeName."'",
			$node, 1,
		       );
	}
	undef($ret_nodeName) if !length($ret_nodeName);
	if ( $self->has_nodeClass ) {
		# general nested XML support
		my $marshaller = $ctx->base->get($self->nodeClass);
		my $new_ctx = $ctx->next_ctx(
			$node->namespaceURI,
			$node->localname,
		       );
		my $value = ( $marshaller ? $marshaller->marshall_in_element(
			$node,
			$new_ctx,
		       )
				      : $node );
		$ctx->element_ok(1);
		return ($self->attrName => $value, $ret_nodeName);
	}
	else {
		# XML data types
		my $type = $self->has_contents ?
			"XML data" : "presence-only";
		if ($node->hasAttributes) {
			$ctx->exception(
			"Superfluous attributes on $type node",
				$node);
		}
		if ( $self->has_contents ) {
			# simple types, eg Int, Str
			my (@childNodes) = $node->nonBlankChildNodes;
			if ( @childNodes > 1 ) {
				# we could maybe merge CDATA nodes...
				$ctx->exception(
			"Too many child nodes for $type node",
					$node,
				       );
			}
			my $value;
			if ( !@childNodes ) {
				$value = "";
			} else {
				(undef, $value) = $self->contents->accept(
					$childNodes[0],
					$ctx,
				       );
			}
			$ctx->element_ok(1);
			return ($self->attrName => $value, $ret_nodeName);
		}
		else {
			# boolean
			if ( $node->hasChildNodes ) {
				$ctx->exception(
		"Superfluous child nodes on $type node",
					$node,
	       				);
			}
			$ctx->element_ok(1);
			return ($self->attrName => 1, $ret_nodeName);
		}
	}
}

method complete( PRANG::Graph::Context $ctx ) {
	$ctx->element_ok;
}

method expected( PRANG::Graph::Context $ctx ) {
	my $prefix = "";
	my $nodename = $self->nodeName;
	if ( $self->has_xmlns ) {
		my $xmlns = eval { $self->nodeClass->xmlns } ||
			$self->xmlns;
		if ( $prefix = $ctx->rxsi->{$xmlns} ) {
			$prefix .= ":";
		}
		else {
			$prefix = $ctx->get_prefix($xmlns);
			$nodename .= " xmlns:$prefix='$xmlns'";
			$prefix .= ":";
		}
	}
	return "<$prefix$nodename".($self->has_nodeClass?"...":
					    $self->has_contents?"":"/")
		.">";
}

method output ( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx, Item :$value, Int :$slot, Str :$name ) {
	$value //= do {
		my $accessor = $self->attrName;
		$item->$accessor;
	};
	if ( ref $value and ref $value eq "ARRAY" and defined $slot ) {
		$value = $value->[$slot];
	}
	$name //= do {
		if ( $self->has_nodeName_attr ) {
			my $attr = $self->nodeName_attr;
			$item->$attr;
		}
		else {
			$self->nodeName;
		}
	};
	if ( ref $name ) {
		$name = $name->[$slot];
	}

	my $nn;
	my $doc = $node->ownerDocument;
	my $newctx;
	if ( length $name ) {
		my ($xmlns, $prefix, $new_prefix);
		if ( $self->has_xmlns ) {
			$xmlns = $self->xmlns;
			if ( $xmlns eq "*" ) {
				$xmlns = $value->xmlns;
			}
		}
		$ctx = $ctx->next_ctx( $xmlns, $name, $value );
		$prefix = $ctx->prefix;
		my $new_nodeName = ($prefix ? "$prefix:" : "") . $name;
		$nn = $doc->createElement( $new_nodeName );
		if ( $ctx->prefix_new($prefix) ) {
			$nn->setAttribute(
				"xmlns".($prefix?":$prefix":""),
				$xmlns,
			       );
		}
		$node->appendChild($nn);
		# now proceed with contents...
		if ( my $class = $self->nodeClass ) {
			my $m = $ctx->base->get($class);
			if ( !$m and blessed $value ) {
				$m = PRANG::Marshaller->get(ref $value);
			}
			if ( !$m and $value->isa("XML::LibXML::Element") ) {
				for my $att ( $value->attributes ) {
					$nn->setAttribute(
						$att->localname,
						$att->value,
					       );
				}
				for my $child ( $value->childNodes ) {
					my $nn2 = $child->cloneNode;
					$nn->appendChild($nn2);
				}
			}
			else {
				$ctx->exception("tried to serialize unblessed reference")
					if !blessed $value;
				$m->to_libxml($value, $nn, $ctx);
			}
		}
		elsif ( $self->has_contents and defined $value ) {
			my $tn = $doc->createTextNode($value);
			$nn->appendChild($tn);
		}
	}
	else {
		$nn = $doc->createTextNode($value);
		$node->appendChild($nn);
	}
};

with 'PRANG::Graph::Node';

1;

__END__

=head1 NAME

PRANG::Graph::Element - accept a particular type of element

=head1 SYNOPSIS

See L<PRANG::Graph::Meta::Element> source and
L<PRANG::Graph::Node> for examples and information.

=head1 DESCRIPTION

This graph node specifies that the XML graph at this point must accept
a particular type of element.

If the element only has only simple types (eg Str, Bool), it will not
have one of these objects in its graph.

Along with L<PRANG::Graph::Text>, this graph node is the only type
which may actually consume input XML nodes or emit them on output.
The other node types merely change the state in the
L<PRANG::Graph::Context> object.

=head1 ATTRIBUTES

=over

=item B<Str xmlns>

If set, then the XML namespace of this element is expected to be the
value passed (or absent).  This is generally not set if the namespace
of this portion of the graph is the same as the parent class.

=item B<nodeName>

This map is used for emitting and generating error messages.  Also, if
set to C<*> it has special meaning when parsing.  Specifies the name
of the node.

=item B<nodeName_attr>

If set, instances have an attribute which stores the name of the XML
element.

=item B<Str nodeClass>

This specifies the next type of element; during parsing and emitting,
recursion to the meta-object of this class occurs.

This will be undefined if the attribute has C<Bool> type; node
presence is true and absence is false.

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

