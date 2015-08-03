package Svsh::Perp;

use Moo;
use namespace::clean;

with 'Svsh';

=head1 NAME

Svsh::Perp - perp support for svsh

=head1 DESCRIPTION

This class provides support for L<perp|http://b0llix.net/perp/>
to L<svsh> - the supervisor shell.

=head1 IMPLEMENTED METHODS

Refer to L<Svsh> for complete explanation of these methods. Only changes from
the base specifications are listed here.

=head2 status()

C<perp> provides more information about service statuses then
other supervisors. C<down> means the service is down but should be
up (unexpected down), C<disabled> means the service is down because
it was manually stopped, C<resetting> means the service is restarting,
and C<backoff> means the service is attempting to start (possibly failing,
not necessarily).

=cut

sub status {
	my $statuses = {};
	foreach ($_[0]->run_cmd('perpls', '-b', $_[0]->basedir, '-g')) {
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
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'A', @{$_[2]->{args}});
}

=head stop( @services )

This uses the C<X> option of C<perpctl> instead of C<d> or C<D>, as there
seems to be a bug(?) where processes stopped with this option failed to
start again when the L<start()|/"start( @services )"> method is called.

=cut

sub stop {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'X', @{$_[2]->{args}});
}

=head restart( @services )

=cut

sub restart {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'q', @{$_[2]->{args}});
}

=head2 signal( $signal, @services )

=cut

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	my $cmd = $sign =~ m/^usr(1|2)$/i ? $1 : lc(substr($sign, 0, 1));

	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, $cmd, @sv);
}

=head2 fg( $service )

=cut

sub fg {
	# find out the pid of the logging process
	my $text = $_[0]->run_cmd('perpstat', '-b', $_[0]->basedir, $_[2]->{args}->[0]);
	my $pid = ($text =~ m/log:.+\(pid (\d+)\)/)[0]
		|| die "Can't figure out pid of the logging process";

	# find out the current log file
	my $logfile = $_[0]->find_logfile($pid)
		|| die "Can't find out process' log file";

	$_[0]->run_cmd('tail', '-f', $logfile, { as_system => 1 });
}

=head2 rescan()

=cut

sub rescan {
	$_[0]->run_cmd('perphup', $_[0]->basedir);
}

=head2 terminate()

=cut

sub terminate {
	$_[0]->run_cmd('perphup', '-t', $_[0]->basedir);
}

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Svsh@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Svsh>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Svsh::Perp

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
