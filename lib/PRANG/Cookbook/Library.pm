
package PRANG::Cookbook::Library;

use Moose;
use MooseX::Method::Signatures;
use PRANG::Graph;
use PRANG::XMLSchema::Types;

has_element 'book' =>
	xml_nodeName => 'book',
	is => 'rw',
	isa => 'PRANG::Cookbook::Book',
	xml_required => 1,
	;

sub root_element { 'library' }
with 'PRANG::Cookbook';

1;
