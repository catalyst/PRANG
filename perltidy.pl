#!/usr/bin/perl -w
#

use Perl::Tidy;
use File::Find;
use Getopt::Long qw(:config bundling);
use FindBin qw($Bin);
use autodie qw(rename unlink);

my $test_only;
my $perltidyrc = "$Bin/.perltidyrc";
my @dirs;
my $files_regex = qr{\.(pm|t|PL|pl)$};

GetOptions(
	"test|t"        => \$test_only,
	"rc=s"          => \$perltidyrc,
	"include|I=s\@" => \@dirs,
	"files|f=s"     => \$files_regex,
);

if ( !@dirs ) {
	@dirs = qw(lib t);
}

my @files;
if (@ARGV) {
	@files = @ARGV;
}
else {
	find(   sub {
			if ( $_ eq "examples" ) {
				$File::Find::prune = 1;
			}
			elsif (m{$files_regex}) {
				push @files, $File::Find::name;
			}
		},
		"lib",
		"t"
	);
}

my $seen_untidy = 0;

for my $file (@files) {
	local (@ARGV);
	Perl::Tidy::perltidy(
		source      => $file,
		destination => "$file.tidy",
		perltidyrc  => $perltidyrc,
	);

	my $rc = system( "diff -q $file $file.tidy &>/dev/null" );
	if ( !$rc ) {
		unlink("$file.tidy");
	}
	elsif ($test_only) {
		print "$file is UNTIDY\n";
		unlink("$file.tidy");
		$seen_untidy++;
	}
	else {
		print "$file was changed\n";
		rename( "$file.tidy", $file );
	}
}

exit $seen_untidy;
