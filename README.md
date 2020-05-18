# svc-monitor
IBM SAN Volume Controller (SVC) and IBM Storvize Monitor

NAME
    check_svc.pl - SAN Volume Controller (SVC) and IBM Storwize monitoring check script

AUTHOR
    Vladimir Shapovalov <shapovalov@gmail.com>

SYNOPSIS
    check_svc.pl CHECK_COMMAND [SVC_IP/NAME] [USER] [PASS]

CHECK_COMMAND
    check_node
         Displays detailed state information for cluster nodes.

    check_md
         Shows information about managed disks (MDs) in the system.

    check_vv
         Shows information about virtual volumes (VVs) in the system.

    check_pd
         Shows information about physical/local disks (PDs) in the system.

    showalert
         Displays the status of system alerts.

DESCRIPTION
    Script uses Expect to login to SVC controller via ssh. There is no additional software required.

      14.04.20 V0.1 (vs). Initial version
      14.04.20 V0.9 (vs). Draft
      14.04.20 V1.0 (vs). Added commands: check_node
      14.04.20 V1.1 (vs). Added commands: showalert
      05.05.20 V1.2 (vs). Added commands: check_md, check_vv
      10.05.20 V1.3 (vs). Added device:   Storvize added
      16.05.20 V1.4 (vs). Bugfixing:      minor output issues
      18.05.20 V1.5 (vs). Added commands: check_pd

TODO
LICENSE
    MIT License - feel free!

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

EXAMPLES
    Check physical/local diskd (PDs ) #> check_svc.pl check_pd svc.mycompany.net monitor monitor123

    Output:

     OK! 272 PDs online.
     CRITICAL! 3 PDs in FAILED status (id: 2,13,19) (check 'lsdrive')
     WARNING! 2 PDs in DEGRADED status (id: 0,4) (check 'lsdrive')
     CRITICAL! 3 PDs in FAILED status (id: 2,13,19), WARNING! 2 PDs in DEGRADED status (id: 0,4) (check 'lsdrive')

    #> check_svc.pl check_node svc.mycompany.net monitor monitor123

    Output:

     OK! 4 nodes online.
     CRITICAL! nodes in FAILED status   (check 'lsnode/lsnodecanister command): 2 (pci_error, unknown),
     WARNING!  nodes in DEGRADED status (check 'lsnode/lsnodecanister command): 1 (cpu_vrm_overheating,tod_bat_fail)
     CRITICAL! nodes in FAILED status   (check 'lsnode/lsnodecanister command): 2 (pci_error, unknown), WARNING!  nodes in DEGRADED status (check 'lsnode/lsnodecanister command): 1 (cpu_vrm_overheating,tod_bat_fail)

    #> check_svc.pl check_vv svc.mycompany.net monitor monitor123

    Output:

     OK! 130 VVs online.
     CRITICAL! 2 VVs in OFFLINE status (id: 2, 4) (check 'lsvdisk'),
     WARNING!  2 VVs in DEGRADED/EXCLUDED status (id: 3, 5) (check 'lsvdisk'),
     CRITICAL! 2 VVs in OFFLINE status (id: 2, 4) 2 VVs in DEGRADED status (id: 3, 5) (check 'lsvdisk')

    #> check_svc.pl check_md svc.mycompany.net monitor monitor123

    Output:

     OK! 130 MDs online.
     CRITICAL! 2 MDs in OFFLINE status (id: 2, 4), (check 'lsmdisk'),
     WARNING!  2 MDs in DEGRADED/EXCLUDED status (id: 3, 5) (check 'lsmdisk'),
     CRITICAL! 2 MDs in OFFLINE status (id: 2, 4) 2 MDs in DEGRADED/EXCLUDED status (id: 3, 5) (check 'lsmdisk')

    #> check_svc.pl showalert svc.mycompany.net monitor monitor123

    Output:

     OK! There are no unfixed errors.
     CRITICAL! Unfixed messages and alerts available (check 'finderr'): Highest priority unfixed event code is [1010]
