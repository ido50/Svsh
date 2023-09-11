package Svsh::S6;

use Moo;
use namespace::clean;

our $DEFAULT_BASEDIR = '/service';

with 'Svsh';

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

=head2 status()

=cut

sub status {
	my $statuses = {};
	foreach ($_[0]->_service_dirs) {
		my $raw = $_[0]->run_cmd('s6-svstat', $_[0]->basedir.'/'.$_);
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

=head2 start( @services )

=cut

sub start {
	foreach (@{$_[2]->{args}}) {
		$_[0]->run_cmd('s6-svc', '-u', $_[0]->basedir.'/'.$_);
	}
}

=head2 stop( @services )

=cut

sub stop {
	foreach (@{$_[2]->{args}}) {
		$_[0]->run_cmd('s6-svc', '-Dd', $_[0]->basedir.'/'.$_);
	}
}

=head2 restart( @services )

=cut

sub restart {
	foreach (@{$_[2]->{args}}) {
		$_[0]->run_cmd('s6-svc', '-q', $_[0]->basedir.'/'.$_);
	}
}

=head2 signal( $signal, @services )

=cut

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	my $cmd = $sign =~ m/^usr(1|2)$/i ? $1 : lc(substr($sign, 0, 1));

	foreach (@sv) {
		$_[0]->run_cmd('s6-svc', "-$cmd", $_[0]->basedir.'/'.$_);
	}
}

=head2 fg( $service )

=cut

sub fg {
	# find out the pid of the logging process
	my $text = $_[0]->run_cmd('s6-svstat', $_[0]->basedir.'/'.$_[2]->{args}->[0].'/log');
	my $pid = ($text =~ m/\(pid (\d+)\)/)[0]
		|| die "Can't figure out pid of the logging process";

	# find out the current log file
	my $logfile = $_[0]->find_logfile($pid)
		|| die "Can't find out process' log file";

	$_[0]->run_cmd('tail', '-f', $logfile, { as_system => 1 });
}

=head2 rescan()

=cut

sub rescan {
	$_[0]->run_cmd('s6-svscanctl', '-a', $_[0]->basedir);
}

=head2 terminate()

=cut

sub terminate {
	$_[0]->run_cmd('s6-svscanctl', '-t', $_[0]->basedir);
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
