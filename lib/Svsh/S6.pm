package Svsh::S6;

use Moo;
use namespace::clean;

with 'Svsh';

=head1 NAME

Svsh::S6 - s6 support for svsh

=head1 DESCRIPTION

This class provides support for L<s6|http://www.skarnet.org/software/s6/>
to L<svsh> - the supervisor shell.

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
	$_[0]->run_cmd('s6-svscanctl', '-7', $_[0]->basedir);
}

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Svsh@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Svsh>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Svsh::S6

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
