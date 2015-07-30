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
	$_[2]->{args} = [$_[0]->_expand_wildcards(@{$_[2]->{args}})];
};

before signal => sub {
	my ($signal, @svcs) = @{$_[2]->{args}};
	$_[2]->{args} = [$signal, $_[0]->_expand_wildcards(@svcs)];
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

sub _expand_wildcards {
	my $self = shift;

	my %services;
	foreach (@_) {
		if (m/\*/) {
			# this is a wildcard, find all services that match it
			my $regex = $_; $regex =~ s/\*/.*/; $regex = qr/^$regex$/;
			foreach my $sv (grep { m/$regex/ } keys %{$self->statuses}) {
				$services{$sv} = 1;
			}
		} else {
			$services{$_} = 1;
		}
	}

	return keys %services;
}

1;
__END__
