
package PRANG::Graph::Seq;

use Moose;
use MooseX::Method::Signatures;

has 'members' =>
	is => "ro",
	isa => "ArrayRef[PRANG::Graph::Node]",
	default => sub { [] },
	;

method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx ) {
	my $pos = $ctx->seq_pos;
	my ($key, $val, $x, $member);
	do {
		$member = $self->members->[$pos-1]
			or $ctx->exception("unexpected element", $node);
		($key, $val, $x) = $member->accept($node, $ctx);
		if (!$key or !$member->accept_many ) {
			$ctx->seq_pos(++$pos);
		}
	} until ($key);
	($key, $val, $x);
}

method complete( PRANG::Graph::Context $ctx ) {
	my $pos = $ctx->seq_pos;
	my $member;
	my $done;
	while ( !$done ) {
		$member = $self->members->[$pos-1];
		if ( $member and $member->complete($ctx) ) {
			$ctx->seq_pos(++$pos);
		}
		else {
			$done = 1;
		}
	}
	my $cmp = $pos-1 <=> @{$self->members};
	if ( $cmp == 1 ) {
		warn "Accepted too much!!";
	}
	return ( $cmp != -1 );
}

method expected( PRANG::Graph::Context $ctx ) {
	my $pos = $ctx->seq_pos;
	my $member = $self->members->[$pos];
	if ( $member ) {
		return $member->expected($ctx);
	}
	else {
		return "er... nothing?";
	}
}

method output ( Item $item, XML::LibXML::Element $node, PRANG::Graph::Context $ctx ) {
	for my $member ( @{ $self->members } ) {
		$member->output($item,$node,$ctx);
	}
}

with 'PRANG::Graph::Node';

1;
