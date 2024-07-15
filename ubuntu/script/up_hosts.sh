#!/bin/sh
set -eu

#####################################################################
# help
#####################################################################

print_usage_and_exit () {
  cat <<-USAGE 1>&2
Usage   : ${0##*/}
Options :

start a generic Ubuntu docker container
USAGE
  exit 1
}

#####################################################################
# parameter
#####################################################################

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
        exit 1
      fi
      ;;
  esac

  i=$((i + 1))
done

readonly THIS_DIR=$(dirname $0)
readonly TOP_DIR="${THIS_DIR}/.."
readonly DOCKER_DIR="${TOP_DIR}/dockerfile"
readonly DOCKER_FILE="${DOCKER_DIR}/Dockerfile"
readonly DOCKER_COMPOSE="${TOP_DIR}/docker-compose.yml"

if [ ! -f "${DOCKER_FILE}" ] || [ ! -r "${DOCKER_FILE}" ]; then
  echo "${0##*/}: dockerfile not exist" 1>&2
  exit 1
fi

if [ ! -f "${DOCKER_COMPOSE}" ] || [ ! -r "${DOCKER_COMPOSE}" ]; then
  echo "${0##*/}: docker-compose file not exist" 1>&2
  exit 1
fi

#####################################################################
# main routine
#####################################################################

# start the container
(
  cd "${TOP_DIR}"
  docker compose up -d
)
