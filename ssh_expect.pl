#!/usr/bin/perl
#$Id: ssh_expect.pl 1078 2011-06-26 04:54:51Z rohare $
#URL: $
#
use warnings;
use Expect;

sub expect_prompt(){
	my $ssh_exp = shift;
	my $timeout = shift;
	my $prompt = shift;
	$ssh_exp->expect($timeout, '-re' , $prompt)
 		or die "expect error" . $ssh_exp->exp_error() . "\n";
	my $out = $ssh_exp->before();
	return $out;
}

sub remote_copy (){
	my $scp = shift;
	my $ruser = shift;
	my $password = shift;
	my $server = shift;
	my $localpath = shift;
	my $timeout = shift;
	my $prompt = '\$\s*';
	my $spawn_ok;

	my $scp_exp = new Expect;
	$scp_exp->spawn("$scp $localpath $ruser\@$server\:\."); # or die "Cannot spawn ssh: $!\n";

	$scp_exp->expect(5,
		[qr'\(yes/no\)\s*',sub {my $exph = shift; print $exph "yes\r" ;exp_continue; }],
		[qr'word:\s*' , sub {my $exph = shift; print $exph "$password\r";exp_continue; }],
		[EOF => sub {die "Error: Could not login!\n"; }],
		[timeout => sub {die "Error: Could not login!\n"; }], '-re', '\$');

# $scp_exp->expect($timeout, '-re' ,'word:\s*') or die "nok";
# # print $scp_exp "$password\r";
# # $scp_exp->expect($timeout, '-re' , $prompt) or return "scp finished!\n";
# $scp_exp->soft_close();
#
# Check md5sum @todo
#
}

sub remote_install (){
	my $ssh = shift;
	my $ruser = shift;
	my $password = shift;
	my $server = shift;
	my $lfile = shift;
	my $timeout = shift;
	my $prompt = '\$\s*';
	my $root_prompt = '\#\s*';
	my $spawn_ok;

	my $ssh_exp = new Expect;
	$ssh_exp->spawn("$ssh $ruser\@$server") or die "Cannot spawn ssh: $!\n";
	$ssh_exp->expect($timeout, '-re' ,'word:\s*') or die "nok";
	print $ssh_exp "$password\r";
	&expect_prompt($ssh_exp, $timeout, $prompt);

	print $ssh_exp "ls\r";
	my $list = &expect_prompt($ssh_exp, $timeout, $prompt);
	print "\n******** Remote FILE LIST *******\n $list \n";
	print "*********************************\n\n";
	$ssh_exp->hard_close();
}

#--------------------------------------------------------------
# Main
#--------------------------------------------------------------

my $scp = "/usr/bin/scp";
my $ssh = "/usr/bin/ssh";
my $ruser = "rohare";
my $rpass;
my $rserver = "192.168.0.2";
my $lfile = "/home/rohare/tmp/junk.txt";
my $timeout = 10;

system "stty -echo";
print "Password: ";
$rpass = <STDIN>;
print "\n";
system "stty echo";

&remote_copy ($scp, $ruser, $rpass, $rserver, $lfile, $timeout);
&remote_install ($ssh, $ruser, $rpass, $rserver, $lfile, $timeout);

exit;

