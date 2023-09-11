package Svsh::Runit;

use Moo;
use namespace::clean;

use Proc::Killall;

our $DEFAULT_BASEDIR = -e '/etc/service' ? '/etc/service' : '/service';

with 'Svsh';

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

=head2 status()

=cut

sub status {
	my $statuses = {};
	foreach ($_[0]->_service_dirs) {
		my $raw = $_[0]->run_cmd('sv', 'status', $_[0]->basedir.'/'.$_);

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
	$_[0]->run_cmd('sv', 'up', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

=head stop( @services )

=cut

sub stop {
	$_[0]->run_cmd('sv', 'down', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

=head restart( @services )

=cut

sub restart {
	$_[0]->run_cmd('sv', 'quit', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

=head signal( $signal, @services )

=cut

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	if ($sign =~ m/^usr(1|2)$/) {
		$sign = $1;
	} elsif ($sign eq 'alrm') {
		$sign = 'alarm';
	} elsif ($sign eq 'int') {
		$sign = 'interrupt';
	}

	$_[0]->run_cmd('sv', lc($sign), map { $_[0]->basedir.'/'.$_ } @sv);
}

=head2 fg( $service )

=cut

sub fg {
	# find out the pid of the logging process
	my $text = $_[0]->run_cmd('sv', 'status', $_[0]->basedir.'/'.$_[2]->{args}->[0]);
	my $pid = ($text =~ m/log: \(pid (\d+)\)/)[0]
		|| die "Can't figure out pid of the logging process";

	# find out the current log file
	my $logfile = $_[0]->find_logfile($pid)
		|| die "Can't find out process' log file";

	$_[0]->run_cmd('tail', '-f', $logfile, { as_system => 1 });
}

=head2 terminate()

=cut

sub terminate {
	my $basedir = $_[0]->basedir;
	killall('HUP', "runsvdir $basedir");
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
