
package PRANG::Graph::Choice;

use 5.010;
use Moose;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;

has 'choices' =>
	is => "ro",
	isa => "ArrayRef[PRANG::Graph::Node]",
	default => sub { [] },
	;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'type_map' =>
	is => "ro",
	isa => "HashRef[Str|Moose::Meta::TypeConstraint]",
	predicate => "has_type_map",
	;

has 'name_attr' =>
	is => "ro",
	isa => "Str",
	predicate => "has_name_attr",
	;

method node_ok( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	for my $choice ( @{ $self->choices } ) {
		if ( defined $choice->node_ok($node, $ctx) ) {
			return 1;
		}
	}
	return;
}

method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	my $num;
	my $name = $node->isa("XML::LibXML::Text") ? ""
		: $node->localname;
	my $xmlns = length($name) && $node->namespaceURI;
	my ($key, $val, $x);
	for my $choice ( @{ $self->choices } ) {
		$num++;
		if ( defined $choice->node_ok($node, $ctx) ) {
			($key, $val, $x) = $choice->accept($node, $ctx);
		}
		if ( $key ) {
			$ctx->chosen($num);
			return ($key, $val, $x||eval{$choice->nodeName}||"");
		}
	}
	return ();
}

method complete( PRANG::Graph::Context $ctx ) {
	$ctx->chosen;
}

method expected( PRANG::Graph::Context $ctx ) {
	if ( my $num = $ctx->chosen ) {
		return $self->choices->[$num-1]->expected($ctx);
	}
	else {
		my @choices;
		for my $choice ( @{$self->choices} ) {
			push @choices, $choice->expected($ctx);
		}
		return @choices;
	}
}

our $REGISTRY = Moose::Util::TypeConstraints::get_type_constraint_registry();

method output ( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx, Item $value?, Int $slot? ) {

	my $an = $self->attrName;
	$value //= $item->$an;
	my $name;
	if ( $self->has_name_attr ) {
		my $x = $self->name_attr;
		$name = $item->$x;
		if ( defined $slot ) {
			$name = $name->[$slot];
		}
	}
	elsif ( $self->has_type_map ) {
		my $map = $self->type_map;
		for my $element ( keys %$map ) {
			my $type = $map->{$element};
			if ( ! ref $type ) {
				$type = $map->{$element} =
					$REGISTRY->get_type_constraint($type);
			}
			if ( $type->check($value) ) {
				$name = $element;
				last;
			}
		}
	}
	if ( !defined $name ) {
		$DB::single = 1;
		die "epic fail";
	}
	if ( length $name ) {
		for my $choice ( @{ $self->choices } ) {
			if ( $choice->nodeName eq $name or
				     $choice->nodeName eq "*") {
				$choice->output(
					$item,$node,$ctx,
					$value,$slot,$name,
				       );
				last;
			}
		}
	}
	else {
		# textnode ... jfdi
		my $tn = $node->ownerDocument->createTextNode($value);
		$node->appendChild($tn);
	}
}

with 'PRANG::Graph::Node';

1;
