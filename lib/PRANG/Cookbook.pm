
package PRANG::Cookbook;

use Moose::Role;

BEGIN { with 'PRANG::Graph', 'PRANG::Cookbook::Node'; };

use PRANG::Cookbook::Note;

1;
