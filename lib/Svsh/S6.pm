package Svsh::S6;

use warnings;
use strict;

use Carp;
use IPC::Cmd qw/run/;

=head1 NAME

Svsh::S6 - s6 support for svsh

=head1 DESCRIPTION

This class provides support for L<s6|http://www.skarnet.org/software/s6/>
to L<svsh> - the supervisor shell.

=head2 DEFAULT BASE DIRECTORY

C<s6> does not have a default base directory, but recommends C</service>,
so that is what will be used if a base directory was not provided to C<svsh>.

=head1 IMPLEMENTED METHODS

Refer to L<Svsh> for complete explanation of these methods. Only changes from
the base specifications are listed here.

=cut

sub default_basedir { '/service' }

=head2 status()

=cut

sub status {
    my ($basedir, @service_dirs) = @_;

	my $statuses = {};

	foreach (@service_dirs) {
        my ($ok, $err, $output, $stdout) = run(
            command => ['s6-svstat', $basedir.'/'.$_]
        );

        if (!$ok) {
            confess "s6-svstat failed: $err";
        }

        my $raw = join("", @$stdout);

		my ($status, $comment, $seconds) = ($raw =~ m/(up|down) \(([^\)]+)\) (\d+)/);
		$statuses->{$_} = {
			status => $status,
			duration => $seconds,
			pid => '-'
		};

		if ($comment =~ m/pid (\d+)/) {
			$statuses->{$_}->{pid} = $1;
		}
	}

	return $statuses;
}

sub _run_svc {
    my ($flags, $service_dir) = @_;

    my ($ok, $err, $output, $stdout) = run(
        command => ['s6-svc', $flags, $service_dir]
    );

    if (!$ok) {
        confess "s6-svc failed: $err";
    }

    return join("", @$stdout);
}

=head2 start( @services )

=cut

sub start {
    my ($basedir, @services) = @_;

    foreach (@services) {
        _run_svc('-u', $basedir.'/'.$_);
	}
}

=head2 stop( @services )

=cut

sub stop {
    my ($basedir, @services) = @_;

    foreach (@services) {
        _run_svc('-Dd', $basedir.'/'.$_);
	}
}

=head2 restart( @services )

=cut

sub restart {
    my ($basedir, @services) = @_;

    foreach (@services) {
        _run_svc('-q', $basedir.'/'.$_);
	}
}

=head2 signal( $signal, @services )

=cut

sub signal {
    my ($basedir, $signal, @services) = @_;

	# convert signal to perpctl command
	$signal =~ s/^sig//i;
	my $cmd = $signal =~ m/^usr(1|2)$/i ? $1 : lc(substr($signal, 0, 1));

	foreach (@services) {
        _run_svc("-$cmd", $basedir.'/'.$_);
	}
}

=head2 get_logger_pid( $service )

=cut

sub get_logger_pid {
    my ($basedir, $service) = @_;

	# find out the pid of the logging process
    my ($ok, $err, $output, $stdout) = run(
        command => ['s6-svstat', $basedir.'/'.service.'/log']
    );

    if (!$ok) {
        confess "s6-svstat failed: $err";
    }

    my $text = join("", @$stdout);

	my $pid = ($text =~ m/\(pid (\d+)\)/)[0]
		|| confess "regex did not match";

    return $pid;
}

=head2 rescan()

=cut

sub rescan {
    my $basedir = shift;

    return ['s6-svscanctl', '-a', $basedir];
}

=head2 terminate()

=cut

sub terminate {
    my $basedir = shift;

    return ['s6-svscanctl', '-t', $basedir];
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
