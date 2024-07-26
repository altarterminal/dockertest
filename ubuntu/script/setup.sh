#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/}
Options : -u<user name> -i<uid> -n<num> -p<pakages> -x<proxy> -f

prepare files for generic Ubuntu docker container

-u: specify the user name (default: host's user name)
-i: specify the uid (default: host's uid)
-n: specify the number of container (default: 1)
-p: specify the packages which are to be installed (comma-seperated list)
-x: specify the proxy setting ("address":"port")
-f: specify whether force to re-build the image (default: no)
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

opr=''
opt_u=$(id -un)
opt_i=$(id -u)
opt_n='1'
opt_p=''
opt_x=''
opt_f='no'

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -u*)                 opt_u=${arg#-u}      ;;
    -i*)                 opt_i=${arg#-i}      ;;
    -n*)                 opt_n=${arg#-n}      ;;
    -p*)                 opt_p=${arg#-p}      ;;
    -x*)                 opt_x=${arg#-x}      ;;
    -f)                  opt_f='yes'          ;;
    *)
      if [ $i -eq $# ] && [ -z "$opr" ]; then
        opr=$arg
      else
        echo "${0##*/}: invalid args" 1>&2
        exit 1
      fi
      ;;
  esac

  i=$((i + 1))
done

if [ -z "${opt_u}" ]; then
  echo "${0##*/}: user name must be specified" 1>&2
  exit 1
fi

if ! echo "${opt_i}" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: invalid uid <${opt_i}> specified" 1>&2
  exit 1
fi

if ! echo "${opt_n}" | grep -Eq '^[0-9]+$'; then
  echo "${0##*/}: invalid number <${opt_n}> specified" 1>&2
  exit 1
fi

readonly USER_NAME=${opt_u}
readonly USER_ID=${opt_i}
readonly CONTAINER_NUM=${opt_n}
readonly PACKAGES=${opt_p}
readonly PROXY=${opt_x}
readonly IS_REBUILD=${opt_f}

readonly IMAGE_NAME='gen-ubuntu'

readonly THIS_DIR=$(dirname $0)
readonly TOP_DIR="${THIS_DIR}/.."
readonly DOCKER_DIR="${TOP_DIR}/dockerfile"
readonly TEMPLATE_DIR="${TOP_DIR}/template"
readonly DOCKER_TEMPLATE="${TEMPLATE_DIR}/Dockerfile.template"
readonly DOCKER_FILE="${DOCKER_DIR}/Dockerfile"
readonly DOCKER_COMPOSE="${TOP_DIR}/docker-compose.yml"

#####################################################################
# main routine
#####################################################################

if [ "${IS_REBUILD}" = 'yes' ]; then
  OLD_IMG_ID=$(docker images                                        |
               sed '1d'                                             |
               awk '$1~/^'"${IMAGE_NAME}"'$/ { print $3; }'         )

  if [ -n "${OLD_IMG_ID}" ]; then
    if ! docker rmi "${OLD_IMG_ID}" >/dev/null 2>&1; then
      echo "${0##*/}: cannot delete the old image <${OLD_IMG_ID}>" 1>&2
      exit 1
    fi
  fi
fi

# prepare environment
mkdir -p "${DOCKER_DIR}"
cp "${HOME}/.ssh/id_rsa"     "${DOCKER_DIR}"
cp "${HOME}/.ssh/id_rsa.pub" "${DOCKER_DIR}"

# make a valid dockerfile
cat "${DOCKER_TEMPLATE}"                                            |
sed 's!<<uname>>!'"${USER_NAME}"'!'                                 |
sed 's!<<uid>>!'"${USER_ID}"'!'                                     |
if [ -n "${PACKAGES}" ]; then
  sed 's!<<packages>>!'"$(echo ${PACKAGES} | tr "," " ")"'!'
else
  sed 's!^.*<<packages>>.*$!# no packages specified!'
fi                                                                  |
if [ -n "${PROXY}" ]; then
  sed 's!<<proxy>>!'"${PROXY}"'!g'
else
  sed 's!^.*<<proxy>>.*$!# no proxy specified!'
fi                                                                  |
cat > "${DOCKER_FILE}"

# make a valid docker-compose
i=1
while [ $i -le "${CONTAINER_NUM}" ];
do
  cat <<'  EOF'
  <<image_name>>-no-<<number>>:
    build: ./dockerfile
    image: <<image_name>>
    container_name: <<image_name>>-no-<<number>>
    restart: always
    ports:
      - <<port_number>>:22

  EOF

  i=$((i + 1))
done                                                                |
sed 's!<<image_name>>!'"${IMAGE_NAME}"'!g'                          |
awk -v RS='\n\n' '
BEGIN { 
  port_ini = 50000;
  number   = 1;
}
{ 
  gsub(/<<number>>/,      number,            $0); 
  gsub(/<<port_number>>/, port_ini + number, $0);
  print; print "";
  number++;
}
'                                                                   |
{ echo "services:"; cat; }                                          |
cat > "${DOCKER_COMPOSE}"
