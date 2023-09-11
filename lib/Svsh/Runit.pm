package Svsh::Runit;

use warnings;
use strict;

use Carp;
use IPC::Cmd qw/run/;

=head1 NAME

Svsh::Runit - runit support for svsh

=head1 DESCRIPTION

This class provides support for L<runit|http://smarden.org/runit/>
to L<svsh> - the supervisor shell.

=head2 DEFAULT BASE DIRECTORY

Traditionally, C<runit> used C</etc/service> as the default base directory,
but versions 1.9.0 changed the default to C</service>. C<runit> still recommends
C</etc/service> for FHS compliant systems, so this class uses C</etc/service>
if it exists, or C</service> otherwise, if a base directory is not provided
to C<svsh>.

=head1 IMPLEMENTED METHODS

Refer to L<Svsh> for complete explanation of these methods. Only changes from
the base specifications are listed here.

=cut

sub default_basedir { -e '/etc/service' ? '/etc/service' : '/service' }

=head2 status()

=cut

sub status {
    my ($basedir, @service_dirs) = @_;

	my $statuses = {};

	foreach (@service_dirs) {
        my ($ok, $err, $output, $stdout) = run(
            command => ['sv', 'status', $basedir.'/'.$_]
        );

        if (!$ok) {
            confess "sv failed: $err";
        }

        my $raw = join("", @$stdout);

		my ($status, $pid, $duration) = $raw =~ m/^([^:]+):[^:]+:(?: \(pid (\d+)\))? (\d+)s/;

		$status = 'up'
			if $status eq 'run';

		$statuses->{$_} = {
			status => $status,
			duration => $duration || 0,
			pid => $pid || '-'
		};
	}
	return $statuses;
}

=head start( @services )

=cut

sub start {
    my ($basedir, @services) = @_;

	return ['sv', 'up', map { $basedir.'/'.$_ } @services];
}

=head stop( @services )

=cut

sub stop {
    my ($basedir, @services) = @_;

	return ['sv', 'down', map { $basedir.'/'.$_ } @services];
}

=head restart( @services )

=cut

sub restart {
    my ($basedir, @services) = @_;

	return ['sv', 'quit', map { $basedir.'/'.$_ } @services];
}

=head signal( $signal, @services )

=cut

sub signal {
	my ($basedir, $signal, @services) = @_;

	# convert signal to perpctl command
	$signal =~ s/^sig//i;
	if ($signal =~ m/^usr(1|2)$/) {
		$signal = $1;
	} elsif ($signal eq 'alrm') {
		$signal = 'alarm';
	} elsif ($signal eq 'int') {
		$signal = 'interrupt';
	}

	return ['sv', lc($signal), map { $basedir.'/'.$_ } @services];
}

=head2 fg( $service )

=cut

sub get_logger_pid {
    my ($basedir, $service) = @_;

	# find out the pid of the logging process
    my ($ok, $err, $output, $stdout) = run(
        command => ['sv', 'status', $basedir.'/'.$service]
    );

    if (!$ok) {
        confess "sv failed: $err";
    }

    my $text = join("", @$stdout);

	my $pid = ($text =~ m/log: \(pid (\d+)\)/)[0]
		|| confess "regex did not match";

    return $pid;
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
