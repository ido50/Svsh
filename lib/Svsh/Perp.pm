package Svsh::Perp;

use warnings;
use strict;

use Carp;
use IPC::Cmd qw/run/;

=head1 NAME

Svsh::Perp - perp support for svsh

=head1 DESCRIPTION

This class provides support for L<perp|http://b0llix.net/perp/>
to L<svsh> - the supervisor shell.

=head2 DEFAULT BASE DIRECTORY

As per the L<perpboot|http://b0llix.net/perp/site.cgi?page=perpboot.8> documentation,
C<perp> does not have a default base directory, but will check if a C<PERP_BASE> environment
variable is set, and if not, will try C</etc/perp>. This class will do the same if
a base directory is not provided to C<svsh>.

=head1 IMPLEMENTED METHODS

Refer to L<Svsh> for complete explanation of these methods. Only changes from
the base specifications are listed here.

=cut

sub default_basedir {
    return $ENV{PERP_BASE} || '/etc/perp';
}

=head2 status()

C<perp> provides more information about service statuses then
other supervisors. C<down> means the service is down but should be
up (unexpected down), C<disabled> means the service is down because
it was manually stopped, C<resetting> means the service is restarting,
and C<backoff> means the service is attempting to start (possibly failing,
not necessarily).

=cut

sub status {
    my ($basedir) = @_;

	my $statuses = {};

    my ($ok, $err, $output, $stdout) = run(
        command => ['perpls', '-b', $basedir, '-g']
    );

    if (!$ok) {
        confess "perpls failed: $err";
    }

	foreach (@$stdout) {
		chomp;
		my @m = m/^
			\[
				.\s			# the perpd status
				(.)(.)(.)\s		# the process status
				...			# the logger status
			\]\s+
			(\S+)\s+			# the process name
			(?:
				uptime:\s+
				([^\/]+)s		# the process uptime
				\/
				\S+s			# the logger uptime
				\s+
				pids:\s+
				([^\/]+)		# the process pid
				\/
				\S+			# the logger pid
			)?				# optional because inactive services will not have this
		/x;

		my $status = $m[0] eq '+' ? $m[2] eq 'r' ? 'resetting' : 'up' :
				 $m[0] eq '.' ? 'down' :
				 $m[0] eq '!' ? 'backoff' :
				 $m[0] eq '-' ? 'disabled' : 'unknown';

		$statuses->{$m[3]} = {
			status => $status,
			pid => $status eq 'up' ? $m[5] : '-',
			duration => $status eq 'up' ? $m[4] eq '-' ? 0 : int($m[4]) : 0
		};
	}

	return $statuses;
}

=head start( @services )

This uses the C<A> option of C<perpctl> instead of C<u> or C<U>, see
L<stop()|/"stop( @services )"> why.

=cut

sub start {
    my ($basedir, @services) = @_;

	return ['perpctl', '-b', $basedir, 'A', @services];
}

=head stop( @services )

This uses the C<X> option of C<perpctl> instead of C<d> or C<D>, as there
seems to be a bug(?) where processes stopped with this option failed to
start again when the L<start()|/"start( @services )"> method is called.

=cut

sub stop {
    my ($basedir, @services) = @_;

	return ['perpctl', '-b', $basedir, 'X', @services];
}

=head restart( @services )

=cut

sub restart {
    my ($basedir, @services) = @_;

	return ['perpctl', '-b', $basedir, 'q', @services];
}

=head2 signal( $signal, @services )

=cut

sub signal {
	my ($basedir, $signal, @services) = @_;

	# convert signal to perpctl command
	$signal =~ s/^sig//i;
	my $cmd = $signal =~ m/^usr(1|2)$/i ? $1 : lc(substr($signal, 0, 1));

	return ['perpctl', '-b', $basedir, $cmd, @services];
}

=head2 fg( $service )

=cut

sub get_logger_pid {
    my ($basedir, $service) = @_;

	# find out the pid of the logging process
    my ($ok, $err, $output, $stdout) = run(
        command => ['perpstat', '-b', $basedir, $service]
    );

    if (!$ok) {
        confess "perpstat failed: $err";
    }

    my $text = join("", @$stdout);

	my $pid = ($text =~ m/log:.+\(pid (\d+)\)/)[0]
		|| confess "regex did not match";

    return $pid;
}

=head2 rescan()

=cut

sub rescan {
    my $basedir = shift;

    return ['perphup', $basedir];
}

=head2 terminate()

=cut

sub terminate {
    my $basedir = shift;

    return ['perphup', '-t', $basedir];
}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
L<https://github.com/ido50/Svsh/issues>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

Thanks to the guys at the L<supervision mailing list|http://skarnet.org/lists.html#supervision>,
especially Colin Booth, for helping out with suggestions and information.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015-2023, Ido Perlmuter C<< ido@ido50.net >>.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
__END__
