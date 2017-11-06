#!/bin/bash

# Babs Gordon

# Collection of boilerplate Buildkite steps. Write 'em here, use 'em wherever

# RTFM
usage() {
  cat <<RTFM

Usage: babsg command [options]

Commands:

  help    displays this message
  build   builds the Dockerfile and pushes to ECR
  rubocop runs rubocop in your docker container

RTFM
}

build() {
  set -euo pipefail

  echo "--- :buildkite: :pipeline: generating BUILD_VERSION"
  BUILD_VERSION=$(date -u +"%Y%m%d%H%M%S")-$BUILDKITE_COMMIT-$BUILDKITE_BUILD_NUMBER-$BUILDKITE_BUILD_ID

  cat <<EOF | buildkite-agent pipeline upload
env:
  BUILD_VERSION: $BUILD_VERSION
EOF

  echo "--- :docker: building container :construction_worker:"
  docker build -t app .

  echo "--- :docker: tag and push to :aws:"
  docker tag app $BABSG_DOCKER_URL:$BUILD_VERSION
  docker push $BABSG_DOCKER_URL:$BUILD_VERSION
}

pytest() {
  set -euo pipefail

  echo "--- :docker::snake: testing :hurtrealbad:"
  docker run --rm --entrypoint /bin/bash \
    $BABSG_DOCKER_URL:$BUILD_VERSION \
    -c python -m unittest discover -s ./tests -p '*_test.py'

  echo '👌 Tests passed! :godmode:'
}

rspec() {
  set -euo pipefail

  echo "--- :docker::rspec: testing :hurtrealbad:"
  docker run --rm --entrypoint /bin/bash \
    $BABSG_DOCKER_URL:$BUILD_VERSION \
    -c 'bundle exec rake spec'

  echo '👌 Tests passed! :godmode:'
}

rubocop() {
  set -euo pipefail

  echo "--- :docker::rubocop: linting :face_punch:"
  docker run --rm --entrypoint /bin/bash \
    $BABSG_DOCKER_URL:$BUILD_VERSION \
    -c 'bundle exec rubocop'

  echo '👌 Looks good to me! :godmode:'
}

# first arg is the command
unset COMMAND
case $1 in
  build)              COMMAND=build;;
  pytest)             COMMAND=pytest;;
  rspec)              COMMAND=rspec;;
  rubocop)            COMMAND=rubocop;;
  help | -h | --help) COMMAND=usage;;
  # catch borked commands
  *) echo "BORK BORK BORK"; usage; exit 1;;
esac
shift

# parse remaining args
while [ "$1" != "" ]; do
  KEY=$(echo "$1" | awk -F= '{print $1}')
  VALUE=$(echo "$1" | awk -F= '{print $2}')
  case $KEY in
    # catch borked options
    *)           echo "BORK BORK BORK"; usage; exit 1;;
  esac
  shift
done

$COMMAND
