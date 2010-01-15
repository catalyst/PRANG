#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use XML::LibXML;
use t::Octothorpe;

# In this test, the element acceptor is used individually.

my $parser = XML::LibXML->new;
my $doc = $parser->parse_string(<<XML);
<tests>
  <ok>
    <Octothorpe><colon/></Octothorpe>
    <Octothorpe><emdash/><colon></colon></Octothorpe>
    <Octothorpe><colon>Larry Gets the colon</colon></Octothorpe>
    <Ampersand><apostrophe><emdash/><colon/></apostrophe></Ampersand>
    <Ampersand>
        <interpunct>2</interpunct>
        <apostrophe><colon/></apostrophe>
    </Ampersand>
    <Caret><braces>2</braces></Caret>
    <Caret><parens><apostrophe><emdash/><colon/></apostrophe></parens></Caret>
  </ok>
  <fail>
    <Octothorpe desc="missing a required element">
    </Octothorpe>
    <Octothorpe desc="text passed for Bool element">
      <emdash>x</emdash><colon></colon>
    </Octothorpe>
    <Octothorpe desc="attribute passed on Bool element">
      <emdash foo="bar"><colon>x</colon></emdash>
    </Octothorpe>
    <Ampersand desc="bad value for Int xml data element">
      <interpunct>two</interpunct><apostrophe><colon /></apostrophe>
    </Ampersand>
    <Ampersand desc="attribute passed on xml data element">
      <interpunct lang="en">2</interpunct>
      <apostrophe><colon /></apostrophe>
    </Ampersand>
    <Ampersand desc="missing required element">
      <interpunct>2</interpunct> 
    </Ampersand>
    <Caret desc="alternation required, nothing given">
    </Caret>
    <Caret desc="single alternation required, passed multiple">
      <braces>2</braces>
      <parens><apostrophe><emdash/><colon/></apostrophe></parens>
    </Caret>
  </fail>
</tests>
XML

{
	# replace the recursive part of the marshall process with a
	# mock that says where was recursed to
	package Dummy::Marshaller;
	sub get { bless [ $_[1] ], __PACKAGE__ }
	sub marshall_in_element { return \${$_[0]}[0] }
	sub isa { 1 }
	# this eliminates recursion on the way out.
	sub to_libxml { }
}

my $test_num = 1;

for my $oktest ( $doc->findnodes("//ok/*") ) {
	next unless $oktest->isa("XML::LibXML::Element");
	my @nodes = $oktest->childNodes;
	my $class = $oktest->localname;
	my $context = PRANG::Graph::Context->new(
		xpath => "//ok/$class\[position()=$test_num]",
		xsi => { "" => "" },
		base => (bless{},"Dummy::Marshaller"),
		#base => PRANG::Marshaller->get($class),
		prefix => "",
	       );
	my %rv = eval { $class->meta->accept_childnodes( \@nodes, $context ) };
	for my $slot ( keys %rv ) {
		if ( (ref($rv{$slot})||"") eq "SCALAR" ) {
			$rv{$slot} = bless {}, ${$rv{$slot}};
		}
	}
	is($@, "", "ok test $test_num ($class) - no exception");

	my $thing = eval{ $class->new(%rv) };
	ok($thing, "created new $class OK") or diag("exception: $@");

	my $node = $doc->createElement($class);
	$context->reset;
	eval { $class->meta->to_libxml($thing, $node, $context) };
	is($@, "", "ok test $test_num - output elements no exception");
	my @wrote_nodes = $node->childNodes;
	@nodes = grep { !( $_->isa("XML::LibXML::Text")
				   and $_->data =~ /\A\s*\Z/) }
		@nodes;
	is(@wrote_nodes, @nodes,
	   "ok test $test_num - correct number of child nodes") or do {
		   diag("expected: ".$oktest->toString);
		   diag("got: ".$node->toString);
	   };
	$test_num++;
}

$test_num = 1;
for my $failtest ( $doc->findnodes("//fail/*") ) {
	next unless $failtest->isa("XML::LibXML::Element");
	my @nodes = $failtest->childNodes;
	my $class = $failtest->localname;
	my $context = PRANG::Graph::Context->new(
		xpath => "//fail/$class\[position()=$test_num]",
		xsi => { "" => "" },
		base => (bless{},"Dummy::Marshaller"),
		#base => PRANG::Marshaller->get($class),
		prefix => "",
	       );
	my %rv = eval { $class->new(
		$class->meta->accept_childnodes( \@nodes, $context )
	       ) };
	isnt("$@", "", "fail test $test_num - exception raised");
	if ( my $err_re = $failtest->getAttribute("error") ) {
		like("$@", qr/$err_re/,
		     "fail test $test_num - exception string OK");
	}
	$test_num++;
}
