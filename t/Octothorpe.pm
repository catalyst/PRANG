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
with "PRANG::Graph", "PRANG::Graph::Class";

package Ampersand;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";

has_element "interpunct" =>
	is => "ro",
	isa => "Int",
	predicate => "has_interpunct",
	;
has_element "apostrophe" =>
	is => "ro",
	isa => "Octothorpe",
	;

package Caret;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";

has_element "solidus" =>
	is => "ro",
	isa => "Octothorpe|Int",
	xml_nodeName => {
		"braces" => "Int",
		"parens" => "Octothorpe",
	},
	;

package Asteriks;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";

has_element "bullet" =>
	is => "ro",
	isa => "ArrayRef[Str|Int]",
	xml_max => 5,
	xml_nodeName => {
		"umlout" => "Int",
		"guillemets" => "Str",
	},
	;

package Pilcrow;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";

has_element "backslash" =>
	is => "ro",
	isa => "ArrayRef[Asteriks]",
	xml_required => 0,
	;

package Deaeresis;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";

has_element "asterism" =>
	is => "ro",
	isa => "ArrayRef[Caret|Pilcrow|Str]",
	xml_nodeName => {
		"space" => "Caret",
		"underscore" => "Pilcrow",
		"slash" => "Str",
	},
	;

package Fingernails;
use Moose;
sub xmlns {}
use PRANG::Graph;
has_attr "currency" =>
	is => "ro",
	isa => "Str",
	xml_name => "dollar_sign",
	;
has_element "fishhooks" =>
	is => "ro",
	isa => "Deaeresis",
	;

with "PRANG::Graph::Class";
