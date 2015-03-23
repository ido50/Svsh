package Svsh;

# ABSTRACT: Process supervision shell for Perp and S6

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

use Moo::Role;

has 'basedir' => (
	is => 'ro',
	required => 1
);

has 'bindir' => (
	is => 'ro'
);

requires qw/status start stop restart enable disable signal rescan terminate fg/;

sub run_cmd {
	my ($self, $cmd, @args) = @_;

	$cmd = $self->bindir . '/' . $cmd
		if $self->bindir;

	system($cmd, @args);
}

1;
__END__
