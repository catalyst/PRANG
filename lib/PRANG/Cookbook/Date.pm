
package PRANG::Cookbook::Date;

use Moose;
use PRANG::Graph;
use PRANG::Cookbook::Role::Date;

with 'PRANG::Cookbook::Role::Date', 'PRANG::Cookbook::Node';

1;
