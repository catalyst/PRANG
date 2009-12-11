
package PRANG::Util;

use Sub::Exporter -setup =>
	{ exports => [ qw(types_of) ] };

use Set::Object qw(set);

# 12:20 <@mugwump> is there a 'Class::MOP::Class::subclasses' for roles?
# 12:20 <@mugwump> I want a list of classes that implement a role
# 12:37 <@autarch> mugwump: I'd kind of like to see that in core
sub types_of {
	my @types = @_;
	# resolve type names to meta-objects;
	for ( @types ) {
		if ( !ref $_ ) {
			$_ = $_->meta;
		}
	}
	my $known = set(@types);
	my @roles = grep { $_->isa("Moose::Meta::Role") } @types;

	if ( @roles ) {
		$known->remove(@roles);
		for my $mc ( Class::MOP::get_all_metaclass_instances ) {
			next if !$mc->isa("Moose::Meta::Class");
			next if $known->includes($mc);
			if ( grep { $mc->does_role($_->name) } @roles ) {
				$known->insert($mc);
			}
		}
	}
	for my $class ( $known->members ) {
		my @subclasses = map { $_->meta } $class->subclasses;
		$known->insert(@subclasses);
	}
	$known->members;
}

1;
