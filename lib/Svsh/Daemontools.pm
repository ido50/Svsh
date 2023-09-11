package Svsh::Daemontools;

use warnings;
use strict;

use Carp;
use IPC::Cmd qw/run/;

=head1 NAME

Svsh::Daemontools - daemontools support for svsh

=head1 DESCRIPTION

This class provides support for L<daemontools|http://cr.yp.to/daemontools.html>
to L<svsh> - the supervisor shell.

=head2 DEFAULT BASE DIRECTORY

C<daemontools> uses C</service> as its default base directory. If a base directory
is not provided to C<svsh>, that is what will be used.

=head1 IMPLEMENTED METHODS

Refer to L<Svsh> for complete explanation of these methods. Only changes from
the base specifications are listed here.

=cut

sub default_basedir {
    return '/service';
}

=head2 status()

=cut

sub status {
    my ($basedir, @service_dirs) = @_;

	my $statuses = {};

	foreach (@service_dirs) {
        my ( $ok, $err, $output ) = run( command => ['svstat', $basedir.'/'.$_] );

        if (!$ok) {
            confess "svstat failed: $err";
        }

        my $raw = join("", @$output);

		my ($status, $pid, $duration) = $raw =~ m/$_: (\w+)(?: \(pid (\d+)\))? (\d+) seconds/;

		$statuses->{$_} = {
			status => $status,
			duration => $duration || 0,
			pid => $pid || '-'
		};
	}

	return $statuses;
}

=head2 start( @services )

=cut

sub start {
    my ($basedir, @services) = @_;

    return ['svc', '-u', map { $basedir.'/'.$_ } @services];
}

=head2 stop( @services )

=cut

sub stop {
    my ($basedir, @services) = @_;

	return ['svc', '-d', map { $basedir.'/'.$_ } @services];
}

=head2 restart( @services )

This is implemented by sending the C<TERM> signal to the services, as opposed to the
usual C<QUIT> signal, since C<daemontools> does not provide a way of sending the
C<QUIT> signal. Future versions might reimplement this with perl's C<kill> function.

=cut

sub restart {
    my ($basedir, @services) = @_;

	return ['svc', '-t', map { $basedir.'/'.$_ } @services];
}

=head2 signal( $signal, @services )

C<USR1>, C<USR2>, C<QUIT> and C<WINCH> are not supported by C<daemontools>.

=cut

sub signal {
    my ($basedir, $signal, @services) = @_;

	# convert signal to perpctl command
	$signal =~ s/^sig//i;
	die "daemontools does not support the $signal signal"
		if lc($signal) =~ m/^(usr\d|quit|winch)$/;

	return ['svc', '-'.lc(substr($signal, 0, 1)), map { $basedir.'/'.$_ } @services];
}

=head2 get_logger_pid( $basedir, $service )

=cut

sub get_logger_pid {
    my ($basedir, $service) = @_;

	# find out the pid of the logging process
	my ($ok, $err, $output, $stdout) = run(command => ['svstat', $basedir.'/'.$service.'/log']);

    if (!$ok) {
        confess "svstat failed: $err";
    }

    my $text = join("", @$stdout);

	my $pid = ($text =~ m/up \(pid (\d+)\)/)[0]
		|| confess "regex did not match";

    return $pid;
}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to L<https://github.com/ido50/Svsh/issues>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

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
