package Svsh::Daemontools;

use Moo;
use namespace::clean;

our $DEFAULT_BASEDIR = '/service';

with 'Svsh';

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

=head2 status()

=cut

sub status {
	my $statuses = {};
	foreach ($_[0]->_service_dirs) {
		my $raw = $_[0]->run_cmd('svstat', $_[0]->basedir.'/'.$_);

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
	$_[0]->run_cmd('svc', '-u', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

=head2 stop( @services )

=cut

sub stop {
	$_[0]->run_cmd('svc', '-d', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

=head2 restart( @services )

This is implemented by sending the C<TERM> signal to the services, as opposed to the
usual C<QUIT> signal, since C<daemontools> does not provide a way of sending the
C<QUIT> signal. Future versions might reimplement this with perl's C<kill> function.

=cut

sub restart {
	$_[0]->run_cmd('svc', '-t', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

=head2 signal( $signal, @services )

C<USR1>, C<USR2>, C<QUIT> and C<WINCH> are not supported by C<daemontools>.

=cut

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	die "daemontools does not support the $sign signal"
		if lc($sign) =~ m/^(usr\d|quit|winch)$/;

	$_[0]->run_cmd('svc', '-'.lc(substr($sign, 0, 1)), map { $_[0]->basedir.'/'.$_ } @sv);
}

=head2 fg( $service )

=cut

sub fg {
	# find out the pid of the logging process
	my $text = $_[0]->run_cmd('svstat', $_[0]->basedir.'/'.$_[2]->{args}->[0].'/log');
	my $pid = ($text =~ m/up \(pid (\d+)\)/)[0]
		|| die "Can't figure out pid of the logging process";

	# find out the current log file
	my $logfile = $_[0]->find_logfile($pid)
		|| die "Can't find out process' log file";

	$_[0]->run_cmd('tail', '-f', $logfile, { as_system => 1 });
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
