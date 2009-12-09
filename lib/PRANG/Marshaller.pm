
package PRANG::Marshaller;

use Moose;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;

use XML::LibXML 1.70;

BEGIN {
	class_type 'Moose::Meta::Class';
	class_type "XML::LibXML::Element";
	class_type "XML::LibXML::Node";
	role_type "PRANG::Graph";
};

has 'class' =>
	isa => "Moose::Meta::Class",
	is => "ro",
	required => 1,
	;

our %marshallers;  # could use MooseX::NaturalKey?
method get($inv: Str $class) {
	if ( ref $inv ) {
		$inv = ref $inv;
	}
	$class->can("meta") or
		die "cannot marshall $class; no ->meta";
	my $meta = $class->meta;
	if ( $meta->does_role("PRANG::Graph") or
		     $meta->does_role("PRANG::Graph::Class")
		    ) {
		$marshallers{$class} ||= do {
			$inv->new( class => $class->meta );
		}
	}
	else {
		die "cannot marshall ".$meta->name
			."; not a PRANG Class/Node";
	}
}

has 'attributes' =>
	isa => "HashRef[HashRef[PRANG::Graph::Meta::Attr]]",
	is => "ro",
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		my @attr = grep { $_->isa("PRANG::Graph::Meta::Attr") }
			$self->class->get_all_attributes;
		my $default_xmlns = eval { $self->class->name->xmlns };
		my %attr_ns;
		for my $attr ( @attr ) {
			my $xmlns = $attr->has_xmlns ?
				$attr->xmlns : $default_xmlns;
			my $xml_name = $attr->has_xml_name ?
				$attr->xml_name : $attr->name;
			$attr_ns{$xmlns}{$xml_name} = $attr;
		}
		\%attr_ns;
	};

has 'elements' =>
	isa => "ArrayRef[PRANG::Graph::Meta::Element]",
	is => "ro",
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		my @elements = grep {
			$_->isa("PRANG::Graph::Meta::Element")
		} $self->class->get_all_attributes;
		my @e_c = map { $_->associated_class->name } @elements;
		my %e_c_does;
		for my $parent ( @e_c ) {
			for my $child ( @e_c ) {
				if ( $parent eq $child ) {
					$e_c_does{$parent}{$child} = 0;
				}
				else {
					$e_c_does{$parent}{$child} =
						( $child->does($parent)
							  ? 1 : -1 );
				}
			}
		}
		[ map { $elements[$_] } sort {
			$e_c_does{$e_c[$a]}{$e_c[$b]} or
				($elements[$a]->insertion_order
					 <=> $elements[$b]->insertion_order)
			} 0..$#elements ];
	};

has 'acceptor' =>
	is => "rw",
	isa => "PRANG::Graph::Node",
	lazy => 1,
	required => 1,
	default => sub {
		$_[0]->build_acceptor;
	},
	;

method parse( Str $xml ) {

	my $dom = XML::LibXML->load_xml(
		string => $xml,
	       );

	my $rootNode = $dom->documentElement;
	my $rootNodeNS = $rootNode->namespaceURI;
	my $expected_ns = $self->class->name->xmlns;

	if ( $rootNodeNS and $expected_ns ) {
		if ( $rootNodeNS ne $expected_ns ) {
			die "Namespace mismatch: expected '$expected_ns', found '$rootNodeNS'";
		}
	}
	my $xsi = {};
	my $rv = $self->marshall_in_element(
		$rootNode,
		$xsi,
		"/".$rootNode->nodeName,
	       );
	$rv;
}

method marshall_in_element( XML::LibXML::Node $node, HashRef $xsi, Str $xpath ) {
	my $attributes = $self->attributes;
	my @node_attr = grep { $_->isa("XML::LibXML::Attr") }
		$node->attributes;
	my @ns_attr = $node->getNamespaces;

	if ( @ns_attr ) {
		$xsi = { %$xsi,
			 map { ($_->declaredPrefix||"") => $_->declaredURI }
				 @ns_attr };
	}

	my @init_args;

	# process attributes
	for my $attr ( @node_attr ) {
		my $prefix = $attr->prefix;
		if ( !defined $prefix ) {
			$prefix = $node->prefix||"";
		}
		if ( !exists $xsi->{$prefix} ) {
			die "unknown xmlns prefix '$prefix' on ".
				$node->nodeName." (input line "
					.$node->line_number.")";
		}
		my $xmlns = $xsi->{$prefix};
		my $meta_att = $attributes->{$xmlns}{"*"} ||
			$attributes->{$xmlns}{$attr->localname};

		if ( $meta_att ) {
			# sweet, it's ok
			my $att_name = $meta_att->name;
			push @init_args, $att_name, $attr->value;
		}
		else {
			# fail.
			$DB::single = 1;
			die "invalid attribute '".$attr->name."' on "
				.$node->nodeName.
					($node->line_number ?
						 " (input line ".$node->line_number.")" : "");
		}
	};

	# now process elements
	my @childNodes = $node->nonBlankChildNodes;

	my $acceptor = $self->acceptor;
	my $context = PRANG::Graph::Context->new(
		base => $self,
		xpath => $xpath,
		xsi => $xsi,
		prefix => ($node->prefix||""),
	       );

	my (%init_args, %init_arg_names);
	while ( my $input_node = shift @childNodes ) {
		next if $input_node->nodeType == XML_COMMENT_NODE;
		if ( my ($key, $value, $name) =
			     $acceptor->accept($input_node, $context) ) {
			$context->exception(
				"internal error: missing key",
				$input_node,
			       ) unless $key;
			my $meta_att;
			if ( exists $init_args{$key} ) {
				if ( !ref $init_args{$key} or
					     ref $init_args{$key} ne "ARRAY" ) {
					$init_args{$key} = [$init_args{$key}];
					$init_arg_names{$key} = [$init_arg_names{$key}]
						if exists $init_arg_names{$key};
				}
				push @{$init_args{$key}}, $value;
				if (defined $name) {
					my $idx = $#{$init_args{$key}};
					$init_arg_names{$key}[$idx] = $name;
				}
			}
			else {
				$init_args{$key} = $value;
				$init_arg_names{$key} = $name
					if defined $name;
			}
		}
	}

	if ( !$acceptor->complete($context) ) {
		my (@what) = $acceptor->expected($context);
		$context->exception(
			"Node incomplete; expecting: @what",
			$node,
			);
	}
	# now, we have to take all the values we just got and
	# collapse them to init args
	for my $element ( @{ $self->elements } ) {
		my $key = $element->name;
		next unless exists $init_args{$key};
		if ( $element->has_xml_max and $element->xml_max == 1 ) {
			# expect item
			if ( $element->has_xml_nodeName_attr and
				     exists $init_arg_names{$key} ) {
				push @init_args, $element->xml_nodeName_attr =>
					delete $init_arg_names{$key};
			}
			if (ref $init_args{$key} and
				    ref $init_args{$key} eq "ARRAY" ) {
				$context->exception(
"internal error: we ended up multiple values set for '$key' attribute",
					$node);
			}
			push @init_args, $key => delete $init_args{$key}
		}
		else {
			# expect list
			if ( !ref $init_args{$key} or
				     ref $init_args{$key} ne "ARRAY" ) {
				$init_args{$key} = [$init_args{$key}];
				$init_arg_names{$key} = [$init_arg_names{$key}]
					if exists $init_arg_names{$key};
			}
			if ( $element->has_xml_nodeName_attr and
				     exists $init_arg_names{$key} ) {
				push @init_args,
					$element->xml_nodeName_attr =>
						delete $init_arg_names{$key}
			}
			push @init_args, $key => delete $init_args{$key};
		}
	}
	if (my @leftovers = keys %init_args) {
		$context->exception(
		"internal error: ".@leftovers
			." init arg(s) left over (@leftovers)",
			$node,
		       );
	}
	my $value = eval { $self->class->name->new( @init_args ) };
	if ( !$value ) {
		die "Validation error during processing of $xpath ("
			.$self->class->name." constructor returned "
				."error: $@)";
	}
	else {
		return $value;
	}
}

method build_acceptor( ) {
	my @nodes = map { $_->graph_node } @{ $self->elements };
	if ( @nodes != 1 ) {
		PRANG::Graph::Seq->new(
			members => \@nodes,
		       );
	}
	elsif ( @nodes ) {
		$nodes[0];
	}
}

method xml_version { "1.0" };
method encoding { "UTF-8" };

# nothing to see here ... move along please ...
our $zok;
our %zok_seen;
our @zok_themes = (qw( tmnt octothorpe quantum pokemon hhgg pasta
		       phonetic sins punctuation discworld lotr
		       loremipsum batman tld garbage python pooh
		       norse_mythology ));
our $zok_theme;

our $gen_prefix;

method generate_prefix( Str $xmlns ) {
	if ( $zok or eval { require Acme::MetaSyntactic; 1 } ) {
		my $name;
		do {
			$zok ||= do {
				%zok_seen=();
				if ( defined $zok_theme ) {
					$zok_theme++;
					if ( $zok_theme > $#zok_themes ) {
						$zok_theme = 0;
					}
				}
				else {
					$zok_theme = int(time / 86400)
						% scalar(@zok_themes);
				}
				Acme::MetaSyntactic->new(
					$zok_themes[$zok_theme],
				       );
			};
			do {
				$name = $zok->name;
				if ($zok_seen{$name}++) {
					undef($zok);
					undef($name);
					goto next_theme;
				};
			} while ( length($name) > 10 or
					  $name !~ m{^[A-Za-z]\w+$} );
			next_theme:
		}
			until ($name);
		return $name;
	}
	else {
		# revert to a more boring prefix :)
		$gen_prefix ||= "a";
		$gen_prefix++;
	}
}

method to_xml_doc( PRANG::Graph $item ) {
	my $xmlns = $item->xmlns;
	my $prefix = "";
	if ( $item->can("preferred_prefix") ) {
		$prefix = $item->preferred_prefix;
	}
	my $xsi = { $prefix => ($xmlns||"") };
	# whoops, this is non-reentrant
	%zok_seen=();
	undef($gen_prefix);
	my $doc = XML::LibXML::Document->new(
		$self->xml_version, $self->encoding,
	       );
	my $root = $doc->createElement(
		($prefix ? "$prefix:" : "" ) .$item->root_element,
	       );
	if ( $xmlns ) {
		$root->setAttribute(
			"xmlns".($prefix?":$prefix":""),
			$xmlns,
		       );
	}
	$doc->setDocumentElement( $root );
	my $ctx = PRANG::Graph::Context->new(
		xpath => "/".$root->nodeName,
		base => $self,
		prefix => $prefix,
		xsi => $xsi,
	       );
	$self->to_libxml( $item, $root, $ctx );
	$doc;
}

method to_xml( PRANG::Graph $item ) {
	my $document = $self->to_xml_doc($item);
	$document->toString;
}

method to_libxml( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx ) {

	my $attributes = $self->attributes;
	my $node_prefix = $node->prefix||"";
	while ( my ($xmlns, $att) = each %$attributes ) {
		my $prefix;
		while ( my ($attName, $meta_att) = each %$att ) {
			my $is_optional;
			my $obj_att_name = $meta_att->name;
			if ( $meta_att->has_xml_required ) {
				$is_optional = !$meta_att->xml_required;
			}
			elsif ( $meta_att->has_predicate ) {
				# it's optional
				$is_optional = 1;
			}
			# we /could/ use $meta_att->get_value($item)
			# here, but I consider that to break
			# encapsulation
			my $value = $item->$obj_att_name;
			if ( !defined $value ) {
				die "could not serialize $item; slot "
					.$meta_att->name." empty"
						unless $is_optional;
			}
			else {
				if ( !defined $prefix ) {
					$prefix = $ctx->get_prefix(
						$xmlns, $item, $node,
					       );
					if ( $prefix eq $node_prefix ) {
						$prefix = "";
					}
					elsif ( $prefix ne "" ) {
						$prefix .= ":";
					}
				}
				$node->setAttribute(
					$prefix.$attName,
					$value,
				       );
			}
		}
	}

	# now child elements - let the graph do the work.
	my $graph = $self->acceptor;
	$graph->output($item, $node, $ctx);

	$node;
}

1;

