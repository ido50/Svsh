package Svsh;

our $VERSION = "1.003000";
$VERSION = eval $VERSION;

use warnings;
use strict;

use Carp;
use IPC::Cmd qw/run/;

=head1 NAME

Svsh - Process supervision shell for daemontools/perp/s6/runit (library)

=head1 SYNOPSIS

    use Svsh;

    my $svsh = Svsh->new('Perp', '/var/run/services');

    $svsh->restart('web-server');

=head1 DESCRIPTION

C<svsh> is a shell for process supervision suites of the C<daemontools> family,
including C<perp>, C<s6> and C<runit>. Refer to L<svsh> for documentation of
the shell itself. This file documents the library backing the command line
shell, and how to add support for other process supervisors.

=head1 CONSTRUCTOR

=head2 new( $suite, $basedir, \%opts )

Creates a new Svsh instance.

C<$suite> is the class of the supervision suite. Svsh supports 'Daemontools',
'Perp', 'Runit', and 'S6' out of the box, but custom classes can also be
provided. When using one of the official supervision classes, the C<Svsh::>
prefix may be omitted.

C<$basedir> is the base directory from which the process supervisor is managing
services. If not provided, the default directory for the selected suite is used.

C<\%opts> is an optional hash-ref of options that customize Svsh's behavior.
The only option currently supported is "collapse", a boolean option indicating
to L<collapse|svsh/"COLLAPSE"> services when displaying status.

=cut

sub new {
    my ($class, $suite, $basedir, $opts) = @_;

    if (!$suite) {
        confess "The suite class must be provided";
    }

    if (!$basedir) {
        confess "The base directory must be provided";
    }

    if ($suite eq 'Daemontools' || $suite eq 'Perp' || $suite eq 'Runit' || $suite eq 'S6') {
        $suite = "Svsh::$suite";
    }

    eval "require $suite";
    croak $@ if @_;

	-e $basedir && -d $basedir
		|| confess("Base directory $basedir does not exist or is not a directory");

    $opts ||= {};
    $opts->{suite} = $suite;
    $opts->{basedir} = $basedir || $suite->default_basedir;

    return bless $opts, $class;
}

=head1 METHODS

=head2 suite()

Returns the name of the supervisor class.

=cut

sub suite {
    my $self = shift;

    return $self->{suite};
}

=head2 basedir()

Returns the base directory from which the process supervisor is managing
services.

=cut

sub basedir {
    my $self = shift;

    return $self->{basedir};
}

=head2 collapse()

Returns a boolean value indicating whether the L<collapse|svsh/"COLLAPSE">
option is enabled.

=cut

sub collapse {
    my $self = shift;

    return $self->{collapse} || 0;
}

sub $self->_call_suite_method {
    my ($self, $desc, $method, @args) = @_;

    eval {
        if (!defined &{"${self->suite}::$method"}) {
            croak "${self->suite} doesn't implement $method";
        }

        return &{"${self->suite}::$method"}(@args);
    };

    if ($@) {
        croak "Failed ${desc}: $@";
    }
}

=head2 status()

Finds all services managed by the supervisor and returns their statuses.

=cut

sub status {
    my $self = shift;
    return $self->_call_suite_method('running status', 'status', $self->basedir);
}

=head2 start( @services )

Starts a list of services if they are down.

=cut

sub start {
    my ($self, @services) = @_;
    return $self->_call_suite_method('starting services', 'start', $self->basedir, @services);
}

=head2 stop( @services )

Stops a list of services (should not restart them).

=cut

sub stop {
    my ($self, @services) = @_;
    return $self->_call_suite_method('stopping services', 'stop', $self->basedir, @services);
}

=head2 restart( @services )

Stops and starts a list of services. Generally, this is implemented with a
C<QUIT> signal to the services, but check with the specific adapter class.

=cut

sub restart {
    my ($self, @services) = @_;
    return $self->_call_suite_method('restarting services', 'restart', $self->basedir, @services);
}

=head2 signal( $signal, @services )

Sends a UNIX signal to a list of services.

=cut

sub signal {
    my ($self, $signal, @services) = @_;
    return $self->_call_suite_method('signalling services', 'signal', $self->basedir, $signal, @services);
}

=head2 fg( $service )

Finds the log file to which a service is writing, and displays it on screen with
the C<tail -f> command.

=cut

sub fg {
    my ($self, $service, $nlines) = @_;

    $nlines ||= 10;

    my $logger_pid = $self->_call_suite_method('getting logger PID', 'get_logger_pid', $self->basedir, $service);

	my $exe = readlink("/proc/$pid/exe")
		|| confess "Can't tell which logger is used";

	my $file;

	if ($exe =~ m/tinylog/ || $exe =~ m/s6-log/ || $exe =~ m/svlogd/ || $exe =~ m/multilog/) {
		# look for a link to a /current file under /proc/$pid/fd
		opendir my $dir, "/proc/$pid/fd";
		($file) = grep { m!/current$! } map { readlink("/proc/$pid/fd/$_") } grep { !/^\.\.?$/ } readdir $dir;
		closedir $dir;
	}

    if (!$file) {
        confess "Failed finding log file";
    }

    my $fh = IO::File->new($file, 'r')
        || confess "Failed openning log file $file: $!";

    my @last_lines;
    while (defined(my $line = $fh->getline)) {
        push(@last_lines, $line);
        shift @last_lines if scalar @last_lines > $nlines;
    }
    print @last_lines;

    while (1) {
        while (defined(my $line = $fh->getline)) {
            print $line;
        }

        sleep(1);
    }
}

=head2 rescan()

Causes the supervisor to rescan the service directory to find new or removed
services. Not all supervisor suites support this method.

=cut

sub rescan {
    $self->_call_suite_method('rescanning', 'rescan');
}

=head2 terminate()

Terminates the supervisor. Should also terminate all running services. Not all
supervisor suites support this method.

=cut

sub terminate {
    $self->_call_suite_method('terminating', 'terminate');
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
