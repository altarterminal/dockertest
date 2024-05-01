#!/bin/sh
set -eu

######################################################################
# setting
######################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
	Usage   : ${0##*/} -i<ipaddr> -p<port>
	Options : -u<user-name>

	add a jenkins agent

	-i: specify the agent IP address
	-p: specify the agent port number
	-u: specify the user name (default: jenkins)
	USAGE
  exit 1
}

######################################################################
# param
######################################################################

opr=''
opt_i=''
opt_p=''
opt_u='jenkins'
jarg_1=''
jarg_2=''
jarg_3=''

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -i*)                 opt_i=${arg#-i}      ;;
    -p*)                 opt_p=${arg#-p}      ;;
    -u*)                 opt_u=${arg#-u}      ;;
    *)
      if   [ -z "$opr" ]; then
        opr=$arg
      elif [ -z "$jarg_1" ]; then
        jarg_1=$arg
      elif [ -z "$jarg_2" ]; then
        jarg_2=$arg
      elif [ -z "$jarg_3" ]; then
        jarg_3=$arg
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

if [ -u "$opt_u" ]; then
  echo "${0##*/}: user name must be specified" 1>&2
  exit 41
fi

iaddr=${opt_i}
pnum=${opt_p}
uname=${opt_u}
cmd=${opr}
cmdarg1=${jarg_1}
cmdarg2=${jarg_2}
cmdarg3=${jarg_3}

######################################################################
# main routine
######################################################################

# the number of cmd arg is not determined, so the quote is removed for args
ssh -l "${uname}" -p "${pnum}" "${iaddr}" \
   "${cmd}" ${cmdarg1} ${cmdarg2} ${cmdarg3}
