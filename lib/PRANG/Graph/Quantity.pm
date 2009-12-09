
package PRANG::Graph::Quantity;

use Moose;
use MooseX::Method::Signatures;

has 'min' =>
	is => "ro",
	isa => "Int",
	predicate => "has_min",
	;

has 'max' =>
	is => "ro",
	isa => "Int",
	predicate => "has_max",
	;

has 'child' =>
	is => "ro",
	isa => "PRANG::Graph::Node",
	required => 1,
	;

has 'attrName' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

sub accept_many { 1 }

method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	my $found = $ctx->quant_found;
	my $ok = defined $self->child->node_ok($node, $ctx);
	return if not $ok;
	my ($key, $value, $x) = $self->child->accept($node, $ctx)
		or $ctx->exception(
			"internal error: node ok, but then not accepted?",
			$node,
		       );
	$found++;
	$ctx->quant_found($found);
	if ( $self->has_max and $found > $self->max ) {
		$ctx->exception("node appears too many times", $node);
	}
	($key, $value, $x);
}

method complete( PRANG::Graph::Context $ctx ) {
	my $found = $ctx->quant_found;
	return !( $self->has_min and $found < $self->min );
}

method expected( PRANG::Graph::Context $ctx ) {
	my $desc;
	if ( $self->has_min ) {
		if ( $self->has_max ) {
			$desc = "between ".$self->min." and ".$self->max;
		}
		else {
			$desc = "at least ".$self->min;
		}
	}
	else {
		if ( $self->has_max ) {
			$desc = "optionally up to ".$self->max;
		}
		else {
			$desc = "zero or more";
		}
	}
	my @expected = $self->child->expected($ctx);
	return("($desc of: ", @expected, ")");
}

method output ( Object $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx ) {
	my $attrName = $self->attrName;
	my $val = $item->$attrName;
	if ( $self->has_max and $self->max == 1 ) {
		# this is an 'optional'-type thingy
		if ( defined $val ) {
			$self->child->output($item,$node,$ctx,$val);
		}
	}
	else {
		# this is an arrayref-type thingy
		if ( !$val and !$self->has_min ) {
			# ok, that's fine
		}
		elsif ( $val and (ref($val)||"") ne "ARRAY" ) {
			# that's not
			die "item $item / slot $attrName is $val, not"
				."an ArrayRef";
		}
		else {
			for ( my $i = 0; $i <= $#$val; $i++) {
				$ctx->quant_found($i+1);
				$self->child->output(
					$item,$node,$ctx,$val->[$i],$i,
				       );
			}
		}
	}
}

with 'PRANG::Graph::Node';

1;
