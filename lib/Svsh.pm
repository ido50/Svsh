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

has 'collapse' => (
	is => 'rw',
	default => sub { 0 }
);

has 'statuses' => (
	is => 'ro',
	writer => '_set_statuses'
);

requires qw/status start stop restart signal rescan terminate fg logfile/;

before [qw/start stop restart/] => sub {
	my %services;
	foreach (@{$_[2]->{args}}) {
		if (m/\*/) {
			# this is a wildcard, find all services that match it
			my $regex = $_; $regex =~ s/\*/.*/; $regex = qr/^$regex$/;
			foreach my $sv (grep { m/$regex/ } keys %{$_[0]->statuses}) {
				$services{$sv} = 1;
			}
		} else {
			$services{$_} = 1;
		}
	}

	$_[2]->{args} = [keys %services];
};

around 'status' => sub {
	my ($orig, $self) = (shift, shift);
	$self->_set_statuses($orig->($self, @_));
	return $self->statuses;
};

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
