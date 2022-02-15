#!/usr/bin/perl

##################################################
#   SVC/Storvize monitoring check script
##################################################
#   14.04.20 V0.1 (vs). Initial version
#   14.04.20 V0.9 (vs). Draft
#   14.04.20 V1.0 (vs). Added commands: check_node
#   14.04.20 V1.1 (vs). Added commands: showalert
#   05.05.20 V1.2 (vs). Added commands: check_md, check_vv
#   10.05.20 V1.3 (vs). Added device:   Storvize added
#   16.05.20 V1.4 (vs). Bugfixing:      minor output issues
#   18.05.20 V1.5 (vs). Added commands: check_pd
##################################################

=head1 NAME

B<check_svc.pl> - SAN Volume Controller (SVC) and IBM Storwize monitoring check script

=head1 AUTHOR

Vladimir Shapovalov <shapovalov@gmail.com>

=head1 SYNOPSIS

B<check_svc.pl> CHECK_COMMAND [SVC_IP/NAME] [USER] [PASS]

=head1 CHECK_COMMAND

=over 5

=item B<check_node>

Displays detailed state information for cluster nodes.

=item B<check_md>

Shows information about managed disks (MDs) in the system.

=item B<check_vv>

Shows information about virtual volumes (VVs) in the system.

=item B<check_pd>

Shows information about physical/local disks (PDs) in the system.

=item B<showalert>

Displays the status of system alerts.

=back

=head1 DESCRIPTION

Script uses Expect to login to SVC controller via ssh. There is no additional software required.

  14.04.20 V0.1 (vs). Initial version
  14.04.20 V0.9 (vs). Draft
  14.04.20 V1.0 (vs). Added commands: check_node
  14.04.20 V1.1 (vs). Added commands: showalert
  05.05.20 V1.2 (vs). Added commands: check_md, check_vv
  10.05.20 V1.3 (vs). Added device:   Storvize added
  16.05.20 V1.4 (vs). Bugfixing:      minor output issues
  18.05.20 V1.5 (vs). Added commands: check_pd

=head1 TODO



=head1 LICENSE

MIT License - feel free!

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 EXAMPLES

=cut

use strict;
use Data::Dumper;
use Expect;

my $VERSION = 'V1.5';
my $timeout = 60;
my $srv = "";
my $user = "";
my $pass = "";
my $countNodes = 0;
my $productName = 'svc'; #product_name: IBM SAN Volume Controller
#my $productName = 'storvize'; #product_name: IBM Storwize V7000
my @params;
my %checkCommands = (
                      'check_node'  => '"lssystem | grep product_name;lsnode;lsnodecanister"', # Displays the detailed state information for all cluster nodes.
                      'check_pd'    => 'lsdrive -delim :', # Displays configuration information about a system's physical/local disks.
                      'check_md'    => 'lsmdisk -delim :', # Shows managed disks   (MDs) status.
                      'check_vv'    => 'lsvdisk -delim :', # Shows virtual disks/volumes (VVs) status.
                      'showalert'   => 'finderr', # Displays the status of system unfixed errors.
                    );
my %returnCodes   = (
                      'OK'        => '0',
                      'WARNING'   => '1',
                      'CRITICAL'  => '2',
                      'UNKNOWN'   => '3',
                    );
my $returnState    = 'UNKNOWN';
my $checkCommand = $ARGV[0];
if(!$checkCommand || $checkCommand eq ""){
  print "Incorrect usage: check_svc.pl CHECK_COMMAND [SVC_IP/NAME] [USER] [PASS]\n";
  exit $returnCodes{'CRITICAL'};
}
if(!$checkCommands{$checkCommand}){
  print "Incorrect usage (invalid CHECK_COMMAND): check_svc.pl CHECK_COMMAND [SVC_IP/NAME] [USER] [PASS]\n";
  print "commands:\n".join( "\n", keys(%checkCommands))."\n";
  exit $returnCodes{'CRITICAL'};
}

$srv  = $ARGV[1] if ($ARGV[1]);
$user = $ARGV[2] if ($ARGV[2]);
$pass = $ARGV[3] if ($ARGV[3]);

if(!$srv){
  print "Incorrect usage (invalid SVC_IP/NAME): check_svc.pl CHECK_COMMAND [SVC_IP/NAME] [USER] [PASS]\n";
  exit $returnCodes{'CRITICAL'};
}

my $sshStr = "/usr/bin/ssh $user\@$srv";
my $command = $sshStr." ".$checkCommands{$checkCommand};

my $exp = Expect->spawn($command, @params) or die "Cannot spawn $command: $!\n";
$exp->log_stdout(undef);

my $output;
my @out;

@out = $exp->expect($timeout,
           [ qr/assword:/ => sub { my $exp = shift;
                                 $exp->send("$pass\n");
                                 $output = $exp->exp_after;
                                 exp_continue; } ],
           [ qr/sure you want to continue connecting \(yes\/no/i => sub { my $exp = shift;
                                 $exp->send("yes\n");
                                 $output = $exp->exp_after;
                                 exp_continue; } ],
          ) or die("could not spawn... $!");

# replace CRLF with LF
$out[3] =~ s/[\x0A\x0D][\x0A\x0D]/\n/gms;

if($exp->exitstatus() > 0){
  if($checkCommand eq "check_node" && $out[3] =~ /product_name/i){

  }
  else{
    print "ERROR: cannot execute command:\n$command\n$out[3]$out[1]\n";
    exit $returnCodes{'CRITICAL'};
  }
}

if($checkCommand eq "check_pd"){

=pod

Check physical/local diskd (PDs
)
#> B<check_svc.pl> check_pd svc.mycompany.net monitor monitor123

Output:

 OK! 272 PDs online.
 CRITICAL! 3 PDs in FAILED status (id: 2,13,19) (check 'lsdrive')
 WARNING! 2 PDs in DEGRADED status (id: 0,4) (check 'lsdrive')
 CRITICAL! 3 PDs in FAILED status (id: 2,13,19), WARNING! 2 PDs in DEGRADED status (id: 0,4) (check 'lsdrive')

=cut

<<'COMMENT';
#> lsdrive

Use the lsdrive command to display configuration information and drive
vital product data (VPD).

lsdrive output
+-----------------+---------------------------------------------------+
| Attribute       | Value                                             |
+-----------------+---------------------------------------------------+
| status          | Indicates the status. The values are:             |
|                 |  * online                                         |
|                 |  * offline                                        |
|                 |  * degraded                                       |
+-----------------+---------------------------------------------------+
COMMENT

  my %pds;
  my $pdsTotal    = 0;
  my $pdsFailed   = 0;
  my $pdsDegraded = 0;
  my $pdsNew      = 0;
  my $strOut          = "OK! ";
  my $strOutFailed    = "PDs in FAILED status (id: ";
  my $strOutDegraded  = "PDs in DEGRADED status (id: ";

  my @res = split("\n", $out[3]);
  my $iter = 1;
  $iter = 2 if($res[0] =~ /^\s*$/);

  foreach my $i ($iter..$#res){
    next if($res[$i] =~ /^\s*$/);

    if($res[$i] =~ /:offline:/){
      $res[$i] =~ /^(\d+):/;
      $strOutFailed .= $1.", ";
      $pdsFailed++;
    }
    elsif($res[$i] =~ /:degraded:/){
      $res[$i] =~ /^(\d+):/;
      $strOutDegraded .= $1.", ";
      $pdsDegraded++;
    }
    else{}
    $pdsTotal++;
  }
  $strOut .= $pdsTotal." PDs online.";
  $returnState = 'OK';

  if($pdsFailed   > 0){
    $strOutFailed =~ s/,\s+$//;
    $strOut     =  "CRITICAL! ".$pdsFailed." ".$strOutFailed.") (check 'lsdrive')";
    $returnState = 'CRITICAL';
  }
  if($pdsDegraded > 0){
    $strOutDegraded =~ s/,\s+$//;
    $strOut     =  "WARNING! ".$pdsDegraded." ".$strOutDegraded.") (check 'lsdrive')";
    $returnState = 'WARNING';
  }
  if($pdsFailed   > 0 && $pdsDegraded > 0){
    $strOut     =  "CRITICAL! ".$pdsFailed." ".$strOutFailed.") ".$pdsDegraded." ".$strOutDegraded.") (check 'lsdrive')";
    $returnState = 'CRITICAL';
  }
  if($pdsTotal eq "0"){
    $strOut = "UNKNOWN! NO local disks in the system available.";
    $returnState = 'UNKNOWN';
  }

  print "$strOut\n";
  $exp->soft_close();
  exit $returnCodes{$returnState};
}
elsif($checkCommand eq "check_node"){

=pod

#> B<check_svc.pl> check_node svc.mycompany.net monitor monitor123

Output:

 OK! 4 nodes online.
 CRITICAL! nodes in FAILED status   (check 'lsnode/lsnodecanister command): 2 (pci_error, unknown),
 WARNING!  nodes in DEGRADED status (check 'lsnode/lsnodecanister command): 1 (cpu_vrm_overheating,tod_bat_fail)
 CRITICAL! nodes in FAILED status   (check 'lsnode/lsnodecanister command): 2 (pci_error, unknown), WARNING!  nodes in DEGRADED status (check 'lsnode/lsnodecanister command): 1 (cpu_vrm_overheating,tod_bat_fail)

=cut

<<'COMMENT';
#> lsnode

lsnode (SVC) / lsnodecanister (Storwize family products)

Use the lsnode/ lsnodecanister command to return a concise list or a
detailed view of nodes  or node canisters that are part of the clustered
system (system).

Description

This command returns a concise list or a detailed view of nodes or node
canisters that are part of the system. Table 12 provides the possible
values that are applicable to the attributes that are displayed as data
in the output views. 

Node status return codes:
+-----------------+---------------------------------------------------+
| Attribute       | Value                                             |
+-----------------+---------------------------------------------------+
| status          | Indicates the status. The values are:             |
|                 |  * offline                                        |
|                 |  * service                                        |
|                 |  * flushing                                       |
|                 |  * pending                                        |
|                 |  * online                                         |
|                 |  * adding                                         |
|                 |  * deleting                                       |
|                 |  * spare                                          |
+-----------------+---------------------------------------------------+
COMMENT

  my $nodesTotal    = 0;
  my $nodesFailed   = 0;
  my $nodesDegraded = 0;
  my $strOut          = "OK! ";
  my $strOutFailed    = "CRITICAL! nodes in FAILED status   (check 'lsnode/lsnodecanister command'): ";
  my $strOutDegraded  = "WARNING!  nodes in DEGRADED status (check 'lsnode/lsnodecanister command'): ";
  my $strOutMissing   = "CRITICAL! a node is missing. Check your configuration.";

  $out[3] =~ s/^\s*product_name\s+(.*)//;
  $productName = $1;
  $out[3] =~ s/^\s*rbash.*lsnode.*?command not found(.*)//;
  $out[3] =~ s/rbash.*lsnodecanister.*?command not found(.*)//;
  my @res = split("\n", $out[3]);
  foreach my $i (2..$#res){
    next if($res[$i] =~ /^\s*$/);
    $res[$i] =~ /^\s*(\w+)\s+([\w\-]+)\s+(\w+)\s+(\w+)\s+(.*?)\s*$/;
    if(lc($4) eq "online" || lc($4) eq "spare"){
      #$nodesTotal++;
    }
    elsif(lc($4) eq "offline"){
      $strOutFailed .= "$2 ($4), ";
      $nodesFailed++;
    }
    else{
      $strOutDegraded .= "$2 ($4), ";
      $nodesDegraded++;  
    }
    $nodesTotal++;
  }

  $strOut .= $nodesTotal." nodes online.";
  $returnState = 'OK';

  if($nodesFailed   > 0){
    $strOut =  $strOutFailed;
    $returnState = 'CRITICAL';
  }
  if($nodesDegraded > 0){
    $strOut =  $strOutDegraded;
    $returnState = 'WARNING';
  }
  if($nodesFailed   > 0 && $nodesDegraded > 0){
    $strOut =  $strOutFailed.$strOutDegraded;
    $returnState = 'CRITICAL';
  }
  if($nodesTotal < $countNodes){
    $strOut =  $strOutMissing;
    $returnState = 'CRITICAL';
  }

  print "$strOut\n";
  $exp->soft_close();
  exit $returnCodes{$returnState};
}
elsif($checkCommand eq "check_vv"){

=pod

#> B<check_svc.pl> check_vv svc.mycompany.net monitor monitor123

Output:

 OK! 130 VVs online.
 CRITICAL! 2 VVs in OFFLINE status (id: 2, 4) (check 'lsvdisk'),
 WARNING!  2 VVs in DEGRADED/EXCLUDED status (id: 3, 5) (check 'lsvdisk'),
 CRITICAL! 2 VVs in OFFLINE status (id: 2, 4) 2 VVs in DEGRADED status (id: 3, 5) (check 'lsvdisk')


=cut

<<'COMMENT';
#> lsvdisk -delim :

status   Indicates the status. The value can be online, offline or degraded. 
COMMENT

  my $vvsTotal    = 0;
  my $vvsFailed   = 0;
  my $vvsDegraded = 0;
  my $strOut          = "OK! ";
  my $strOutFailed    = "VVs in OFFLINE status (id: ";
  my $strOutDegraded  = "VVs in DEGRADED status (id: ";

  my @res = split("\n", $out[3]);
  my $iter = 1;
  $iter = 2 if($res[0] =~ /^\s*$/);

  foreach my $i ($iter..$#res){
    next if($res[$i] =~ /^\s*$/);

    if($res[$i] =~ /:offline:/){
      $res[$i] =~ /^(\d+):/;
      $strOutFailed .= $1.", ";
      $vvsFailed++;
    }
    elsif($res[$i] =~ /:degraded:/){
      $res[$i] =~ /^(\d+):/;
      $strOutDegraded .= $1.", ";
      $vvsDegraded++;
    }
    else{}
    $vvsTotal++;
  }
  $strOut .= $vvsTotal." VVs online.";
  $returnState = 'OK';

  if($vvsFailed   > 0){
    $strOutFailed =~ s/,\s+$//;
    $strOut     =  "CRITICAL! ".$vvsFailed." ".$strOutFailed.") (check 'lsvdisk')";
    $returnState = 'CRITICAL';
  }
  if($vvsDegraded > 0){
    $strOutDegraded =~ s/,\s+$//;
    $strOut     =  "WARNING! ".$vvsDegraded." ".$strOutDegraded.") (check 'lsvdisk')";
    $returnState = 'WARNING';
  }
  if($vvsFailed   > 0 && $vvsDegraded > 0){
    $strOut     =  "CRITICAL! ".$vvsFailed." ".$strOutFailed.") ".$vvsDegraded." ".$strOutDegraded.") (check 'lsvdisk')";
    $returnState = 'CRITICAL';
  }

  print "$strOut\n";
  $exp->soft_close();
  exit $returnCodes{$returnState};
}
elsif($checkCommand eq "check_md"){

=pod

#> B<check_svc.pl> check_md svc.mycompany.net monitor monitor123

Output:

 OK! 130 MDs online.
 CRITICAL! 2 MDs in OFFLINE status (id: 2, 4), (check 'lsmdisk'),
 WARNING!  2 MDs in DEGRADED/EXCLUDED status (id: 3, 5) (check 'lsmdisk'),
 CRITICAL! 2 MDs in OFFLINE status (id: 2, 4) 2 MDs in DEGRADED/EXCLUDED status (id: 3, 5) (check 'lsmdisk')

=cut

<<'COMMENT';
#> lsmdisk -delim :

Use the lsmdisk command to display a concise list or a detailed view of
managed disks (MDisks) visible to the clustered system (system). It can
also list detailed information about a single MDisk.

+-----------------+---------------------------------------------------+
| Attribute       | Values                                            |
+-----------------+---------------------------------------------------+
| status          |  * online                                         |
|                 |  * offline                                        |
|                 |  * excluded                                       |
|                 |  * degraded_paths                                 |
|                 |  * degraded_ports                                 |
|                 |  * degraded (applies only to internal MDisks)     |
+-----------------+---------------------------------------------------+

COMMENT

  my $mdsTotal    = 0;
  my $mdsFailed   = 0;
  my $mdsDegraded = 0;
  my $strOut          = "OK! ";
  my $strOutFailed    = "MDs in OFFLINE status (id: ";
  my $strOutDegraded  = "MDs in DEGRADED/EXCLUDED status (id: ";

  $out[3] =~ s/^\s$//gms;

  my @res = split("\n", $out[3]);
  my $iter = 1;
  $iter = 2 if($res[0] =~ /^\s*$/);

  foreach my $i ($iter..$#res){
    next if($res[$i] =~ /^\s*$/);

    if($res[$i] =~ /:offline:/){
      $res[$i] =~ /^(\d+):/;
      $strOutFailed .= $1.", ";
      $mdsFailed++;
    }
    elsif($res[$i] =~ /:degraded:/ || $res[$i] =~ /:degraded_ports:/ || $res[$i] =~ /:degraded_paths:/ || $res[$i] =~ /:excluded:/){
      $res[$i] =~ /^(\d+):/;
      $strOutDegraded .= $1.", ";
      $mdsDegraded++;
    }
    else{}
    $mdsTotal++;
  }
  $strOut .= $mdsTotal." MDs online.";
  $returnState = 'OK';

  if($mdsFailed   > 0){
    $strOutFailed =~ s/,\s+$//;
    $strOut     =  "CRITICAL! ".$mdsFailed." ".$strOutFailed.") (check 'lsmdisk)";
    $returnState = 'CRITICAL';
  }
  if($mdsDegraded > 0){
    $strOutDegraded =~ s/,\s+$//;
    $strOut     =  "WARNING! ".$mdsDegraded." ".$strOutDegraded.") (check 'lsmdisk')";
    $returnState = 'WARNING';
  }
  if($mdsFailed   > 0 && $mdsDegraded > 0){
    $strOut     =  "CRITICAL! ".$mdsFailed." ".$strOutFailed.") ".$mdsDegraded." ".$strOutDegraded.") (check 'lsmdisk')";
    $returnState = 'CRITICAL';
  }

  print "$strOut\n";
  $exp->soft_close();
  exit $returnCodes{$returnState};
}
elsif($checkCommand eq "showalert"){

=pod

#> B<check_svc.pl> showalert svc.mycompany.net monitor monitor123

Output:

 OK! There are no unfixed errors.
 CRITICAL! Unfixed messages and alerts available (check 'finderr'): Highest priority unfixed event code is [1010]

=cut

<<'COMMENT';
#> finderr
Use the finderr command to analyze the event log for the highest severity unfixed event.

Description

The command scans the event log for any unfixed events. Given a priority
ordering within the code, the highest priority unfixed event is returned
to standard output.

You can use this command to determine the order in which to fix the
logged event.

The resulting output
Highest priority unfixed event code is [1010]

COMMENT

  my $alertsTotal    = 0;
  my $nodesFailed   = 0;
  my $nodesDegraded = 0;
  my $strOut          = "OK! There are no unfixed errors.";
  my $strOutFailed    = "CRITICAL! Unfixed messages and alerts available (check 'finderr'): ";
  my $strOutDegraded  = "";

  $out[3] =~ s/^\s*$//gms;
  $out[3] =~ s/\n*$//;
  if($out[3] =~ /\n?There are no unfixed errors/i){
    $returnState = 'OK';
  }  
  elsif($out[3] =~ /Highest priority unfixed error code is \[(\d+)\]/i){
    $strOut =  $strOutFailed." ".$out[3];
    $returnState = 'CRITICAL';
  }
  else{
    $strOut =  "UNKNOWN error...  ".$out[3];
    $returnState = 'CRITICAL';
  }

  print "$strOut\n";
  $exp->soft_close();
  exit $returnCodes{$returnState};
}
else{
  print "Incorrect usage (invalid CHECK_COMMAND): check_svc.pl CHECK_COMMAND [SVC_IP/NAME] [USER] [PASS]\n";
  print "commands:\n".join( "\n", keys(%checkCommands))."\n";
  $exp->soft_close();
  exit $returnCodes{'CRITICAL'};
}

$exp->soft_close();

exit;
