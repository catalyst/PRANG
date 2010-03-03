
package PRANG::Cookbook;

use Moose::Role;

BEGIN { with 'PRANG::Graph', 'PRANG::Cookbook::Node'; };

1;
