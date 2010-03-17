#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use inc::Module::Install;

name            ("PRANG");
abstract        ("Moose XML Processor");
author          ("Catalyst SRS Team <team-srs\@catalyst.net.nz>");
version         0.01;
license         ('artistic');

requires        ("perl" => 5.010);
requires        ("Moose" => 0.92);

&WriteAll;
