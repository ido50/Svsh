package Svsh::S6;

use autodie;

use Moo;
use namespace::clean;

with 'Svsh';

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

sub start {
	foreach (@{$_[2]->{args}}) {
		$_[0]->run_cmd('s6-svc', '-u', map { $_[0]->basedir.'/'.$_ } $_);
	}
}

sub stop {
	foreach (@{$_[2]->{args}}) {
		$_[0]->run_cmd('s6-svc', '-Dd', map { $_[0]->basedir.'/'.$_ } $_);
	}
}

sub restart {
	foreach (@{$_[2]->{args}}) {
		$_[0]->run_cmd('s6-svc', '-q', $_[0]->basedir.'/'.$_);
	}
}

sub signal {
	my ($sign, @sv) = @{$_[2]->{args}};

	# convert signal to perpctl command
	$sign =~ s/^sig//i;
	my $cmd = $sign =~ m/^usr(1|2)$/i ? $1 : lc(substr($sign, 0, 1));

	foreach (@sv) {
		$_[0]->run_cmd('s6-svc', "-$cmd", $_[0]->basedir.'/'.$_);
	}
}

sub rescan {
	$_[0]->run_cmd('s6-svscanctl', '-a', $_[0]->basedir);
}

sub terminate {
	$_[0]->run_cmd('s6-svscanctl', '-7', $_[0]->basedir);
}

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

sub _service_dirs {
	my $basedir = shift->basedir;

	opendir(my $dh, $basedir);
	my @dirs = grep { !/^\./ && -d "$basedir/$_" } readdir $dh;
	closedir $dh;

	return sort @dirs;
}

1;
__END__
