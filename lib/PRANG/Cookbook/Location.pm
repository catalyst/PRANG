
package PRANG::Cookbook::Location;

use Moose;
use PRANG::Cookbook::Role::Location;

with 'PRANG::Cookbook::Role::Location', 'XML::SRS::Node';

1;
