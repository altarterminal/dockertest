#!/bin/sh
set -eu

######################################################################
# user setting
######################################################################

cid='auto-credential-id'
desc='description'

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/}
	Options : -c<credintial-ID> -d<description>

	add a jenkins agent

	current setting:
	credential id: "$cid"
	description: "$desc"
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
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@305.v8f4381501156">
  <scope>GLOBAL</scope>
  <id><<cid>></id>
  <description><<desc>></description>
  <username>jenkins</username>
  <usernameSecret>false</usernameSecret>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey$DirectEntryPrivateKeySource">
    <privateKey><<id_rsa>></privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF

awk '
BEGIN {
  frsa = "'${HOME}'/.ssh/id_rsa";

  while ((getline line < frsa) > 0) {
    lineno++;
    rbuf[lineno] = line;
  }
}

!/^ *<privateKey>.*<\/privateKey>$/ { print; }
 /^ *<privateKey>.*<\/privateKey>$/ {
   print "    <privateKey>";
   for (i = 1; i <= lineno; i++) { print rbuf[i]; }
   print "    </privateKey>";
 }
'                                                                     |

sed 's!<<cid>>!'"${cid}"'!'                                           |
sed 's!<<desc>>!'"${desc}"'!'                                         |

cat
