package Svsh::Perp;

use autodie;

use Moo;
use namespace::clean;

with 'Svsh';

sub status {
	$_[0]->run_cmd('perpls', '-b', $_[0]->basedir, '-g');
}

sub start {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'U', @{$_[2]->{args}});
}

sub stop {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'D', @{$_[2]->{args}});
}

sub restart {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'q', @{$_[2]->{args}});
}

sub enable {
	$_[0]->run_cmd('perpctl', '-b', $_[0]->basedir, 'A', @{$_[2]->{args}});
}

sub disable {
	$_[0]->run_cmd('perpc', '-b', $_[0]->basedir, 'X', @{$_[2]->{args}});
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
	my $logfile = $_[0]->find_out_log_file($_[2]->{args}->[0])
		|| return "Can't find out process' log file";

	$_[0]->run_cmd('tail', '-f', $logfile);
}

sub find_out_log_file {
	my ($self, $process) = @_;

	open(my $fh, '<', $self->basedir.'/'.$process.'/rc.log');
	while (<$fh>) {
		chomp;
		if (m!tinylog[^/]+(/[^\s]+)!) {
			my $dir = $1;
			$dir =~ s/\$\{2\}/$process/;
			return $dir.'/current';
		}
	}
	close $fh;

	return;
}

1;
__END__
