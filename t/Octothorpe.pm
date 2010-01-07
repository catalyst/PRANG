package Octothorpe;
use Moose;
sub xmlns {}
sub root_element { "Octothorpe" }
use PRANG::Graph;

has_element "hyphen" =>
	is => "ro",
	isa => "Bool",
	xml_nodeName => "emdash",
	;
has_element "colon" =>
	is => "ro",
	isa => "Str",
	;
has_element "interpunct" =>
	is => "ro",
	isa => "Int",
	predicate => "has_interpunct",
	;
has_element "apostrophe" =>
	is => "ro",
	isa => "Octothorpe",
	;
has_element "solidus" =>
	is => "ro",
	isa => "Octothorpe|Int",
	xml_nodeName => {
		"braces" => "Int",
		"parens" => "Octothorpe",
	},
	;
has_element "bullet" =>
	is => "ro",
	isa => "ArrayRef[Str|Int]",
	xml_max => 5,
	xml_nodeName => {
		"umlout" => "Int",
		"guillemets" => "Str",
	},
	;
has_element "backslash" =>
	is => "ro",
	isa => "ArrayRef[Octothorpe]",
	;
has_element "asterism" =>
	is => "ro",
	isa => "ArrayRef[Octothorpe|Fingernails|Str]",
	xml_nodeName => {
		"space" => "Octothorpe",
		"underscore" => "Fingernails",
		"slash" => "Str",
	},
	;
with "PRANG::Graph", "PRANG::Graph::Class";

package Fingernails;
use Moose;
sub xmlns {}
use PRANG::Graph;
has_attr "currency" =>
	is => "ro",
	isa => "Str",
	xml_name => "dollar_sign",
	;
with "PRANG::Graph::Class";
