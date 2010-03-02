
package PRANG::Cookbook::Note;

use Moose;
use MooseX::Method::Signatures;
use PRANG::Graph;
use PRANG::XMLSchema::Types;

# attributes
has_attr 'replied' =>
	is => 'rw',
	isa => 'PRANG::XMLSchema::boolean',
	required => 0,
	xml_required => 0,
	;

# elements
has_element 'from' =>
	xml_nodeName => 'from',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	;

has_element 'to' =>
	xml_nodeName => 'to',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	;

has_element 'sent' =>
	xml_nodeName => 'sent',
	is => 'rw',
	isa => 'PRANG::Cookbook::DateTime',
	xml_required => 0,
	;

has_element 'subject' =>
	xml_nodeName => 'subject',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	;

has_element 'body' =>
	xml_nodeName => 'body',
	is => 'rw',
	isa => 'Str',
	required => 0,
	xml_required => 0,
	;

sub root_element { 'note' }
with 'PRANG::Cookbook';

1;
