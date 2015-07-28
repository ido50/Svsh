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

requires qw/status start stop restart signal rescan terminate fg logfile/;

sub run_cmd {
	my ($self, $cmd, @args) = @_;

	my $options = {};

	$cmd = $self->bindir . '/' . $cmd
		if $self->bindir && $cmd =~ m/^(perp|s6)/;

	if (scalar @args && ref $args[-1]) {
		$options = pop @args;
	}

	if ($options->{as_system}) {
		system($cmd, @args);
	} else {
		$cmd = join(' ', $cmd, @args);
		return qx/$cmd 2>&1/;
	}
}

sub find_logfile {
	my ($self, $pid) = @_;

	my $exe = readlink("/proc/$pid/exe");

	return unless $exe;

	my $fd =	$exe =~ m/tinylog/ ? 4 :
			$exe =~ m/s6-log/ ? 3 :
			$exe =~ m/svlogd/ ? 6 : 0;

	return unless $fd;

	return readlink("/proc/$pid/fd/$fd").$self->logfile;
}

1;
__END__
