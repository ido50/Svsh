package Svsh::S6;

use autodie;

use Moo;
use namespace::clean;

with 'Svsh';

sub status {
	foreach ($_[0]->service_dirs) {
		$_[0]->run_cmd('s6-svstat', $_[0]->basedir.'/'.$_);
	}
}

sub start {
	$_[0]->run_cmd('s6-svc', '-u', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub stop {
	$_[0]->run_cmd('s6-svc', '-Dd', map { $_[0]->basedir.'/'.$_ } @{$_[2]->{args}});
}

sub enable {
	return "enable is not supported on s6";
}

sub disable {
	return "disable is not supported on s6";
}

sub terminate {
	$_[0]->run_cmd('s6-svscanctl', '-7', $_[0]->basedir);
}

sub fg {
	my $logfile = $_[0]->find_out_log_file($_[2]->{args}->[0])
		|| return "Can't find out process' log file";

	$_[0]->run_cmd('tail', '-f', $logfile);
}

sub find_out_log_file {
	my ($self, $process) = @_;

	open(my $fh, '<', $self->basedir.'/'.$process.'/log/run');
	while (<$fh>) {
		chomp;
		if (m!s6-log[^/]+(/[^\s]+)!) {
			return $1.'/current';
		}
	}
	close $fh;

	return;
}

sub service_dirs {
	my $basedir = shift->basedir;

	opendir(my $dh, $basedir);
	my @dirs = grep { !/^\./ && -d "$basedir/$_" } readdir $dh;
	closedir $dh;

	return sort @dirs;
}

1;
__END__