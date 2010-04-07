package Octothorpe;
use Moose;
sub xmlns {}
sub root_element { "Octothorpe" }
use PRANG::Graph;
# class tests mixed graph structure:
#   Seq -> Quant -> Element
#   Seq -> Element
has_element "hyphen" =>
	is => "ro",
	isa => "Bool",
	xml_nodeName => "emdash",
	predicate => "has_hyphen",
	;
has_element "colon" =>
	is => "ro",
	isa => "Str",
	;
has_element "apostrophe" =>
	is => "ro",
	isa => "Ampersand",
	xml_required => 0,
	;

has_element "pipe" =>
	is => "ro",
	isa => "Fingernails",
	xml_required => 0,
	;

with "PRANG::Graph", "PRANG::Graph::Class";

package Ampersand;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";
# class tests: Quant -> Element
has_element "interpunct" =>
	is => "ro",
	isa => "Int",
	predicate => "has_interpunct",
	;

package Caret;
use Moose;
sub xmlns {}
use PRANG::Graph;
with "PRANG::Graph::Class";
# class tests:
#    Choice -> Element
#    Choice -> Element -> Text
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
# class tests:
#    Quant -> Choice -> Element
#    Quant -> Choice -> Text
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

#    Quant -> Element
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

#    Quant -> Choice with type/nodeName mapping
has_element "asterism" =>
	is => "ro",
	isa => "ArrayRef[Caret|Pilcrow|Str]",
	xml_min => 0,
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
#    Seq -> Element
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

# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
