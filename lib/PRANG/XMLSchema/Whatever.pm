
# Here is the offending definition for this:

#  <complexType name="mixedMsgType" mixed="true">
#    <sequence>
#      <any processContents="skip"
#       minOccurs="0" maxOccurs="unbounded"/>
#    </sequence>
#    <attribute name="lang" type="language"
#     default="en"/>
#  </complexType>

# The mixed="true" part means that we can have character data (the
# validation of which cannot be specified AFAIK).  See
#  http://www.w3.org/TR/xmlschema11-1/#Complex_Type_Definition_details
#
# Then we get an unbounded "any", with processContents="skip"; this
# means that everything under this point - including XML namespace
# definitions, etc - should be completely ignored.  The only
# requirement is that the contents are valid XML.  See
#  http://www.w3.org/TR/xmlschema11-1/#Wildcard_details

# XXX - should really make roles for these different conditions:

#    PRANG::XMLSchema::Wildcard::Skip;
#
#      'skip' specifically means that no validation is required; if
#      the input document specifies a schema etc, that information is
#      to be ignored.  In this instance, we may as well be returning
#      the raw LibXML nodes.

#    PRANG::XMLSchema::Wildcard::Lax;
#
#      processContents="lax" means to validate if the appropriate xsi:
#      etc attributes are present; otherwise to treat as if it were
#      'skip'

#    PRANG::XMLSchema::Wildcard::Strict;

#      Actually this one may not be required; just specifying the
#      'Node' role should be enough.  As 'Node' is not a concrete
#      type, the rest of the namespace and validation mechanism should
#      be able to check that the nodes are valid.

# In addition to these different classifications of the <any>
# wildcard, the enclosing complexType may specify mixed="true";
# so, potentially there are two more roles;

#    PRANG::XMLSchema::Any;              (cannot mix data and elements)
#    PRANG::XMLSchema::Any::Mixed;       (can mix them)

# however dealing with all of these different conditions is currently
# probably premature; the schema we have only contains 'strict' (which
# as noted above potentially needs no explicit support other than
# correct XMLNS / XSI implementation) and 'Mixed' + 'Skip'; so I'll
# make this "Whatever" class to represent this most lax of lax
# specifications.

package PRANG::XMLSchema::Whatever;

use Moose;
use MooseX::Method::Signatures;
use PRANG::Graph;

has_element 'contents' =>
	is => "rw",
	isa => "ArrayRef[PRANG::XMLSchema::Whatever|Str]",
	xml_nodeName => { "" => "Str", "*" => "PRANG::XMLSchema::Whatever" },
	xml_nodeName_attr => "nodenames",
	xmlns => "*",
	;

has 'nodenames' =>
	is => "rw",
	isa => "ArrayRef[Maybe[Str]]",
	;

has_attr 'attributes' =>
	is => "rw",
	isa => "HashRef[Str]",
	xmlns => "*",
	xml_name => "*",
	predicate => 'has_attributes',
	;

method xmlns() {
	# ... meep?
	"";
}

with 'PRANG::Graph::Class';

1;
