#!/bin/sh
set -eu

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -i<ipaddr> -p<port>
	Options : -n<agent-name> -c<credintial-ID>

	add a jenkins agent
	cmd example: create-node auto-agent

	-i: specify the agent IP address
	-p: specify the agent port number
	-c: specify the credential ID (default: auto-credential-id)
	-n: specify the agent name (default: auto-agent)
	USAGE
  exit 1
}

######################################################################
# param
######################################################################

opr=''
opt_i=''
opt_p=''
opt_c='auto-credential-id'
opt_n='auto-agent'

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -i*)                 opt_i=${arg#-i}      ;;
    -p*)                 opt_p=${arg#-p}      ;;
    -c*)                 opt_c=${arg#-c}      ;;
    -n*)                 opt_n=${arg#-n}      ;;
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

if ! printf '%s\n' "$opt_i" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' &&
   [ _"$opt_i" != _'localhost' ]; then
  echo "${0##*/}: invalid ip address specified" 1>&2
  exit 21
fi

if ! printf '%s\n' "$opt_p" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: port must be specified as number" 1>&2
  exit 31
fi

if [ "$opt_p" -lt '49513' ] || [ "$opt_p" -gt 65535 ]; then
  echo "${0##*/}: prohibited port number specified" 1>&2
  exit 32
fi

if [ -z "$opt_c" ]; then
  echo "${0##*/}: credential ID must be specified" 1>&2
  exit 41
fi

if [ -z "$opt_n" ]; then
  echo "${0##*/}: agent name must be specified" 1>&2
  exit 51
fi

iaddr=${opt_i}
pnum=${opt_p}
cid=${opt_c}
aname=${opt_n}

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
  <label></label>
  <nodeProperties/>
</slave>
EOF

sed 's!<<iaddr>>!'"${iaddr}"'!'                                    |
sed 's!<<pnum>>!'"${pnum}"'!'                                      |
sed 's!<<cid>>!'"${cid}"'!'                                        |
sed 's!<<aname>>!'"${aname}"'!'                                    |

cat
