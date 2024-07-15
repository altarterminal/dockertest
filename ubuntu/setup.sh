#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/}
Options : -u<user name> -i<uid> -n<num> -d

make a generic Ubuntu docker container

-u: specify the user name (default: host's user name)
-i: specify the uid (default: host's uid)
-n: specify the number of container (default: 1)
-d: only prepare the files and not run container
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
opt_d='no'

i=1
for arg in ${1+"$@"}
do
  case "$arg" in
    -h|--help|--version) print_usage_and_exit ;;
    -u*)                 opt_u=${arg#-u}      ;; 
    -i*)                 opt_i=${arg#-i}      ;; 
    -n*)                 opt_n=${arg#-n}      ;; 
    -d)                  opt_d='yes'          ;; 
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
readonly IS_DRYRUN=${opt_d}

readonly THIS_DIR=$(dirname $0)
readonly DOCKER_DIR="${THIS_DIR}/dockerfile"
readonly TEMPLATE_DIR="${THIS_DIR}/template"
readonly DOCKER_TEMPLATE="${TEMPLATE_DIR}/Dockerfile.template"
readonly DOCKER_FILE="${DOCKER_DIR}/Dockerfile"
readonly DOCKER_COMPOSE="${THIS_DIR}/docker-compose.yml"

#####################################################################
# main routine
#####################################################################

# prepare environment
mkdir -p "${DOCKER_DIR}"
cp "${HOME}/.ssh/id_rsa"     "${DOCKER_DIR}"
cp "${HOME}/.ssh/id_rsa.pub" "${DOCKER_DIR}"

# make a valid dockerfile
cat "${DOCKER_TEMPLATE}"                                            |
sed 's!<<uname>>!'"${USER_NAME}"'!'                                 |
sed 's!<<uid>>!'"${USER_ID}"'!'                                     |
cat > "${DOCKER_FILE}"

# make a valid docker-compose
yes                                                                 |
head -n "${CONTAINER_NUM}"                                          |
while read -r dummy
do
cat <<EOF
  gen-ubuntu-no-<<number>>:
    build: ./dockerfile
    image: gen-ubuntu
    container_name: gen-ubuntu-no-<<number>>
    restart: always
    ports:
      - <<port_number>>:22

EOF
done                                                                |
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

# start the container
if [ "${IS_DRYRUN}" = 'no' ]; then
  (
    cd "${THIS_DIR}"
    docker compose up -d
  )
fi
