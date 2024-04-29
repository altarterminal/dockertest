#!/bin/sh
set -eu

#####################################################
# setting
#####################################################

rdir=$(dirname $(cd $(dirname $0); pwd))

cfile=${rdir}/docker-compose.yml

#####################################################
# prepare and check
#####################################################

cd "${rdir}"

if [ ! -f "${cfile}" ] || [ ! -r "${cfile}" ]; then
  echo "${0##*/}: setup must be executed before build" 1>&2
  exit 1
fi

#####################################################
# build
#####################################################

docker compose build
