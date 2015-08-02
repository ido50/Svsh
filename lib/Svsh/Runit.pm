package Svsh::Runit;

use Moo;
use namespace::clean;

with 'Svsh';

sub status {
	my $statuses = {};
	foreach ($_[0]->_service_dirs) {
		my $raw = $_[0]->run_cmd('sv', 'status', $_[0]->basedir.'/'.$_);

		my ($status) = $raw =~ m/^([^:]+):/;

		my ($pid, $duration);

		if ($status eq 'run') {
			# the service is up
			$status = 'up';
			($pid, $duration) = $raw =~ m/\(pid (\d+)\) (\d+)s/;
		}

		$statuses->{$_} = {
			status => $status,
			duration => $duration || 0,
			pid => $pid || '-'
		};
	}
	return $statuses;
}

sub start {
	$_[0]->run_cmd('sv', 'up', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub stop {
	$_[0]->run_cmd('sv', 'down', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub restart {
	$_[0]->run_cmd('sv', 'quit', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

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

sub _service_dirs {
	my $basedir = shift->basedir;

	opendir(my $dh, $basedir);
	my @dirs = grep { !/^\./ && -d "$basedir/$_" } readdir $dh;
	closedir $dh;

	return sort @dirs;
}

1;
__END__
