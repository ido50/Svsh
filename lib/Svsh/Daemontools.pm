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

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Svsh@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Svsh>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Svsh::Daemontools

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
