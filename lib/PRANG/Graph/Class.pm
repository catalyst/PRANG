
package PRANG::Graph::Class;

# this is a role which must be mixed into classes which have
# PRANG::Graph::Meta::Attr and PRANG::Graph::Meta::Element attributes

use Moose::Role;

requires 'xmlns';

1;
