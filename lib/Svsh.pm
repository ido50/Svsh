package Svsh;

# ABSTRACT: Process supervision shell for perp/s6/runit

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

=head1 NAME

Svsh - Base class for process supervision suites

=head1 DESCRIPTION

C<svsh> is a shell for process supervision suites such as C<perp>, C<s6> and C<runit>.
Refer to L<svsh> for documentation of the shell itself. This file documents
the base class for Svsh adapter classes.

=cut

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

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Svsh@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Svsh>.

=head1 AUTHOR

Ido Perlmuter <ido at ido50 dot net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015, Ido Perlmuter C<< ido at ido50 dot net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
