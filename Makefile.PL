use inc::Module::Install;

name            ("PRANG");
abstract        ("Moose XML Processor");
author          ("Catalyst SRS Team <team-srs\@catalyst.net.nz>");
version         0;
license         ('artistic');

requires        ("perl" => 5.010);
requires        ("Moose" => 0.92);

&WriteAll;
