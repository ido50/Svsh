package Svsh;

# ABSTRACT: Process supervision shell for daemontools/perp/s6/runit

our $VERSION = "1.002000";
$VERSION = eval $VERSION;

use Moo::Role;

=head1 NAME

Svsh - Process supervision shell for daemontools/perp/s6/runit (base class)

=head1 SYNOPSIS

	package Svsh::SomeSupervisor;

	use Moo;
	use namespace::clean;

	with 'Svsh';

	# implement required methods

=head1 DESCRIPTION

C<svsh> is a shell for process supervision suites of the C<daemontools> family,
including C<perp>, C<s6> and C<runit>. Refer to L<svsh> for documentation of
the shell itself. This file documents the base class for Svsh adapter classes.

=head1 ATTRIBUTES

=head2 basedir

I<Required, Read-Only>.

The base directory from which the process supervisor is managing services.

=cut

has 'basedir' => (
	is => 'ro',
	required => 1
);

=head2 bindir

I<Read-Only>.

The directory where the process supervisor's tools are located. Any call to
the supervisor's tools will be prefixed with this path if provided. For usage
in case the tools are not in the running user's C<PATH> environment variable.

=cut

has 'bindir' => (
	is => 'ro'
);

=head2 collapse

I<Read-Write>.

A boolean indicating whether the L<collapse|svsh/"COLLAPSE"> option should be
enabled.

=cut

has 'collapse' => (
	is => 'rw',
	default => sub { 0 }
);

=head2 statuses

I<Read-Only>.

A hash-ref of services and their statuses (this is automatically populated by
the respective C<status()> method in the adapter classes. For every service,
a hash-ref with C<status>, C<duration> and C<pid> keys should exist.

=cut

has 'statuses' => (
	is => 'ro',
	writer => '_set_statuses'
);

=head1 REQUIRED METHODS

=head2 status()

Finds all services managed by the supervisor, and populates
the L<statuses> attribute.

=head2 start( @services )

Starts a list of services if they are down.

=head2 stop( @services )

Stops a list of services (should not restart them).

=head2 restart( @services )

Stops and starts a list of services. Generally, this is implemented
with a C<QUIT> signal to the services, but check with the specific
adapter class.

=head2 signal( $signal, @services )

Sends UNIX signal to a list of services.

=head2 fg( $service )

Finds the log file to which a service is writing, and displays it
on screen with the C<tail -f> command.

=head1 WANTED METHODS

These methods are not required by adapter classes. If they are not
implemented, they will be unavailable in the shell.

=head2 rescan()

Causes the supervisor to rescan the service directory to find
new or removed services.

=head2 terminate()

Terminates the supervisor. Should also terminate all running services.

=cut

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

=head1 METHODS

=head2 run_cmd( $cmd, [ @args ] )

Runs a shell command with zero or more arguments and returns its
output. If the C<bindir> attribute is set, and the C<$cmd> is one
of the supervision suite's library of tools, C<$cmd> will be prefixed
with C<bindir>.

=cut

sub run_cmd {
	my ($self, $cmd, @args) = @_;

	my $options = {};

	$cmd = $self->bindir . '/' . $cmd
		if $self->bindir && $cmd =~ m/^(perp|s6|sv)/;

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

=head2 find_logfile( $pid )

Finds the log file into which a logging program is currently
writing to. C<$pid> is the process ID of the logging program.
Currently, C<tinylog>, C<s6-log>, C<svlogd> and C<multilog>
are supported.

Returns C<undef> if the file is not found.

=cut

sub find_logfile {
	my ($self, $pid) = @_;

	my $exe = readlink("/proc/$pid/exe")
		|| return;

	my $file;

	if ($exe =~ m/tinylog/ || $exe =~ m/s6-log/ || $exe =~ m/svlogd/ || $exe =~ m/multilog/) {
		# look for a link to a /current file under /proc/$pid/fd
		opendir my $dir, "/proc/$pid/fd";
		($file) = grep { m!/current$! } map { readlink("/proc/$pid/fd/$_") } grep { !/^\.\.?$/ } readdir $dir;
		closedir $dir;
	}

	return $file;
}

######################################################################
# _expand_wildcards( @services )
# goes over a list of services, possibly (but not necessarily)
# with wildcards, and returns a new list with all services
# that match. For example, if @services = ('sv1', 'sv2', 'worker*'),
# and the services worker-1 and worker-2 exist, then the
# method will return ('sv1', 'sv2', 'worker-1', 'worker-2')
######################################################################

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

#########################################################
# _service_dirs()
# returns a list of all service directories inside the
# base directory
#########################################################

sub _service_dirs {
	my $basedir = shift->basedir;

	opendir(my $dh, $basedir);
	my @dirs = grep { !/^\./ && -d "$basedir/$_" } readdir $dh;
	closedir $dh;

	return sort @dirs;
}

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Svsh@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Svsh>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Svsh

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Svsh>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Svsh>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Svsh>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Svsh/>
 
=back

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
