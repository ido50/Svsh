package Svsh::Daemontools;

use Moo;
use namespace::clean;

with 'Svsh';

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

sub start {
	$_[0]->run_cmd('svc', '-u', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub stop {
	$_[0]->run_cmd('svc', '-d', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub restart {
	$_[0]->run_cmd('svc', '-t', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	die "daemontools does not support the $sign signal"
		if lc($sign) =~ m/^(usr\d|quit|winch)$/;

	$_[0]->run_cmd('svc', '-'.lc(substr($sign, 0, 1)), map { $_[0]->basedir.'/'.$_ } @sv);
}

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

1;
__END__
