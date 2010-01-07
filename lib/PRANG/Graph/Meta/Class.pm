package PRANG::Graph::Meta::Class;

use 5.010;
use Moose::Role;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;
use XML::LibXML;

has 'xml_attr' =>
	isa => "HashRef[HashRef[PRANG::Graph::Meta::Attr]]",
	is => "ro",
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		my @attr = grep { $_->does("PRANG::Graph::Meta::Attr") }
			$self->get_all_attributes;
		my $default_xmlns = eval { $self->name->xmlns };
		my %attr_ns;
		for my $attr ( @attr ) {
			my $xmlns = $attr->has_xmlns ?
				$attr->xmlns : $default_xmlns;
			my $xml_name = $attr->has_xml_name ?
				$attr->xml_name : $attr->name;
			$attr_ns{$xmlns//""}{$xml_name} = $attr;
		}
		\%attr_ns;
	};

has 'xml_elements' =>
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

has 'graph' =>
	is => "rw",
	isa => "PRANG::Graph::Node",
	lazy => 1,
	required => 1,
	default => sub {
		$_[0]->build_graph;
	},
	;

method build_graph( ) {
	my @nodes = map { $_->graph_node } @{ $self->xml_elements };
	if ( @nodes != 1 ) {
		PRANG::Graph::Seq->new(
			members => \@nodes,
		       );
	}
	elsif ( @nodes ) {
		$nodes[0];
	}
}

method accept_attributes( ArrayRef[XML::LibXML::Attr] $node_attr, PRANG::Graph::Context $context ) {

	my $attributes = $self->xml_attr;
	my @rv;
	# process attributes
	for my $attr ( @$node_attr ) {
		my $prefix = $attr->prefix;
		if ( !defined $prefix ) {
			$prefix = $context->prefix||"";
		}
		if ( !exists $context->xsi->{$prefix} ) {
			$context->exception("unknown xmlns prefix '$prefix'");
		}
		my $xmlns = $context->get_xmlns($prefix);
		my $meta_att = $attributes->{$xmlns}{"*"} ||
			$attributes->{$xmlns}{$attr->localname};

		if ( $meta_att ) {
			# sweet, it's ok
			my $att_name = $meta_att->name;
			push @rv, $att_name, $attr->value;
		}
		else {
			# fail.
			$context->exception("invalid attribute '".$attr->name."'");
		}
	};
	@rv;
}

method accept_childnodes( ArrayRef[XML::LibXML::Node] $childNodes, PRANG::Graph::Context $context ) {
	my $graph = $self->graph;

	my (%init_args, %init_arg_names);
	my @rv;
	while ( my $input_node = shift @$childNodes ) {
		next if $input_node->nodeType == XML_COMMENT_NODE;
		if ( my ($key, $value, $name) =
			     $graph->accept($input_node, $context) ) {
			$context->exception(
				"internal error: missing key",
				$input_node,
			       ) unless $key;
			my $meta_att;
			# this is long-winded, but lets the fast path avoid
			# too many temporary arrays.
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

	if ( !$graph->complete($context) ) {
		my (@what) = $graph->expected($context);
		$context->exception(
			"Node incomplete; expecting: @what",
			);
	}
	# now, we have to take all the values we just got and
	# collapse them to init args
	for my $element ( @{ $self->xml_elements } ) {
		my $key = $element->name;
		next unless exists $init_args{$key};
		if ( $element->has_xml_max and $element->xml_max == 1 ) {
			# expect item
			if ( $element->has_xml_nodeName_attr and
				     exists $init_arg_names{$key} ) {
				push @rv, $element->xml_nodeName_attr =>
					delete $init_arg_names{$key};
			}
			if (ref $init_args{$key} and
				    ref $init_args{$key} eq "ARRAY" ) {
				$context->exception(
"internal error: we ended up multiple values set for '$key' attribute",
				       );
			}
			push @rv, $key => delete $init_args{$key}
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
				push @rv,
					$element->xml_nodeName_attr =>
						delete $init_arg_names{$key}
			}
			push @rv, $key => delete $init_args{$key};
		}
	}
	if (my @leftovers = keys %init_args) {
		$context->exception(
		"internal error: ".@leftovers
			." init arg(s) left over (@leftovers)",
		       );
	}
	return @rv;
}

method add_xml_attr( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx ) {
	my $attributes = $self->xml_attr;
	my $node_prefix = $node->prefix||"";
	while ( my ($xmlns, $att) = each %$attributes ) {
		my $prefix;
		while ( my ($attName, $meta_att) = each %$att ) {
			my $is_optional;
			my $obj_att_name = $meta_att->name;
			if ( $meta_att->has_xml_required ) {
				$is_optional = !$meta_att->xml_required;
			}
			elsif ( ! $meta_att->is_required ) {
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
}

method to_libxml( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx ) {
	$self->add_xml_attr($item, $node, $ctx);
	$self->graph->output($item, $node, $ctx);
}

package Moose::Meta::Class::Custom::Trait::PRANG;
sub register_implementation { "PRANG::Graph::Meta::Class" }

1;
