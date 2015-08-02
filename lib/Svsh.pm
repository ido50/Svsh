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

requires qw/status start stop restart signal fg/;

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

	my $exe = readlink("/proc/$pid/exe")
		|| return;

	my $file;

	if ($exe =~ m/tinylog/ || $exe =~ m/s6-log/ || $exe =~ m/svlogd/) {
		# look for a link to a /current file under /proc/$pid/fd
		opendir my $dir, "/proc/$pid/fd";
		($file) = grep { m!/current$! } map { readlink("/proc/$pid/fd/$_") } grep { !/^\.\.?$/ } readdir $dir;
		closedir $dir;
	}

	return $file;
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
