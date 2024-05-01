#!/bin/sh
set -eu

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/}
	Options : -c<credintial-ID> -d<description>

	add a jenkins agent
	cmd example: create-credentials-by-xml system::system::jenkins (global)

	-c: specify the credential ID (default: auto-credential-id)
	-d: specify the description (default: this credential has been auto generated)
	USAGE
  exit 1
}

######################################################################
# param
######################################################################

opr=''
opt_c='auto-credential-id'
opt_d='this credential has been auto generated'

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -c*)                 opt_c=${arg#-c}      ;;
    -d*)                 opt_d=${arg#-d}      ;;
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

if [ -z "$opt_c" ]; then
  echo "${0##*/}: credential ID must be specified" 1>&2
  exit 21
fi

cid=${opt_c}
desc=${opt_d}

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
