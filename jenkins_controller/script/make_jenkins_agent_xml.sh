#!/bin/sh
set -eu

######################################################################
# user setting
######################################################################

iaddr='localhost'
pnum='50001'
cid='auto-credential-id'
aname='auto-agent'
label='unix'

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/}
	Options :

	add a jenkins agent

	curret setting:
	agent ip address: "$iaddr"
	agent port number: "$pnum"
	credential id: "$cid"
	agent name: "$aname"
	label: "$label"
	USAGE
  exit 1
}

######################################################################
# param
######################################################################

opr=''

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    *)
      if [ $i -eq $# ] && [ -z "$opr" ]; then
        opr=$arg
      else
        echo "${0##*/}: invalid args" 1>&2
        exit 11
      fi
      ;;
  esac

  i=$((i + 1))
done

######################################################################
# main routine
######################################################################

cat <<'EOF'                                                          |
<slave>
  <name><<aname>></name>
  <description></description>
  <remoteFS>/home/jenkins/work</remoteFS>
  <numExecutors>1</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@2.877.v365f5eb_a_b_eec">
    <host><<iaddr>></host>
    <port><<pnum>></port>
    <credentialsId><<cid>></credentialsId>
    <launchTimeoutSeconds>60</launchTimeoutSeconds>
    <maxNumRetries>10</maxNumRetries>
    <retryWaitTime>15</retryWaitTime>
    <sshHostKeyVerificationStrategy class="hudson.plugins.sshslaves.verifiers.KnownHostsFileKeyVerificationStrategy"/>
    <tcpNoDelay>true</tcpNoDelay>
  </launcher>
  <label><<label>></label>
  <nodeProperties/>
</slave>
EOF

sed 's!<<iaddr>>!'"${iaddr}"'!'                                    |
sed 's!<<pnum>>!'"${pnum}"'!'                                      |
sed 's!<<cid>>!'"${cid}"'!'                                        |
sed 's!<<aname>>!'"${aname}"'!'                                    |
sed 's!<<label>>!'"${label}"'!'                                    |

cat
