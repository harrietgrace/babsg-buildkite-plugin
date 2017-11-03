#!/bin/bash

# Babs Gordon

# Collection of boilerplate Buildkite steps. Write 'em here, use 'em wherever

# RTFM
usage() {
  cat <<RTFM

Usage: babsg command [options]

Commands:

  help (displays this message)

RTFM
}

build() {
  set -euo pipefail

  echo "--- :docker: Building container :construction_worker:"
  docker build -t app .

  echo "--- :docker: tag and push to :aws:"
  docker tag app $BABSG_DOCKER_URL:$BUILD_VERSION
  docker push $BABSG_DOCKER_URL:$BUILD_VERSION
}

# enfore single mode
esm() {
  if [[ -n $MODE ]]; then echo "BORK BORK BORK BORK"; exit 1; fi
}

main() {
  case $MODE in

    build)    build;    exit;;
    usage)    usage;    exit;;
    *)        usage;    exit;;
  esac
}

# we love arg parsing
unset MODE
while [ "$1" != "" ]; do
  KEY=$(echo "$1" | awk -F= '{print $1}')
  VALUE=$(echo "$1" | awk -F= '{print $2}')
  case $KEY in
    # commands
    build)              esm; MODE=build;;
    help | -h | --help) esm; MODE=usage;;
    # catch borked options
    *)           echo "BORK BORK BORK"; usage; exit 1;;
  esac
  shift
done

main
