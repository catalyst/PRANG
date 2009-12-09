
package PRANG::Graph::Node;

use Moose::Role;

sub accept_many { 0 }

#method accept( XML::LibXML::Node $node, PRANG::Graph::Context $ctx )
#  returns ($key, $value, $nodeNameIfAmbiguous)
requires 'accept';

#method complete( PRANG::Graph::Context $ctx )
#  returns Bool
requires 'complete';

#method expected( PRANG::Graph::Context $ctx )
#  returns (@Str) 
requires 'expected';

# method output ( Object $item, XML::LibXML::Element $node, HashRef $xsi ) returns XML::LibXML::Element
requires 'output';

1;
