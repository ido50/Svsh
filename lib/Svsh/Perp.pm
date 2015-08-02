package Svsh::Perp;

use Moo;
use namespace::clean;

with 'Svsh';

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

sub start {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'A', @{$_[2]->{args}});
}

sub stop {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'X', @{$_[2]->{args}});
}

sub restart {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'q', @{$_[2]->{args}});
}

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	my $cmd = $sign =~ m/^usr(1|2)$/i ? $1 : lc(substr($sign, 0, 1));

	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, $cmd, @sv);
}

sub rescan {
	$_[0]->run_cmd('perphup', $_[0]->basedir);
}

sub terminate {
	$_[0]->run_cmd('perphup', '-t', $_[0]->basedir);
}

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

1;
__END__
