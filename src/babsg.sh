#!/bin/bash

# Babs Gordon

# Collection of boilerplate Buildkite steps. Write 'em here, use 'em wherever

# RTFM
usage() {
  cat <<RTFM

Usage: babsg command [options]

Commands:

  help        displays this message

  build       builds the Dockerfile and pushes to ECR

  codeclimate <command>
              runs a command in codeclimate/codeclimate

  pyunittest  runs python unit tests in your docker container to test

  rspec       runs rspec in your docker container to test

  rubocop     runs rubocop in your docker container to lint

  yardoc      runs yard in your docker container to ensure docs are present

RTFM
}

build() {
  set -euo pipefail

  echo "--- :docker: building container :construction_worker:"
  docker build -t app .

  echo "--- :docker: tag and push to :aws:"
  docker tag app "$BABSG_DOCKER_URL:$BUILD_VERSION"
  docker push "$BABSG_DOCKER_URL:$BUILD_VERSION"
}

codeclimate() {
  set -euo pipefail

  echo "--- :docker: running :codeclimate: $@"
  docker run \
    --interactive --tty --rm \
    --env "CODECLIMATE_CODE=$(pwd)" \
    --env CODECLIMATE_REPO_TOKEN \
    --env CC_TEST_REPORTER_ID \
    --env BUILDKITE_BRANCH \
    --env BUILDKITE_COMMIT \
    --env BUILDKITE \
    --env BUILDKITE_JOB_ID \
    --env BUILDKITE_BUILD_URL \
    --volume "$(pwd):/code" \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume /tmp/cc:/tmp/cc \
    codeclimate/codeclimate "$@"
}

pyunittest() {
  set -euo pipefail

  echo "--- :docker::snake: testing :hurtrealbad:"
  docker run \
    --rm \
    --env CODECLIMATE_REPO_TOKEN \
    --env CC_TEST_REPORTER_ID \
    --env BUILDKITE_BRANCH \
    --env BUILDKITE_COMMIT \
    --env BUILDKITE \
    --env BUILDKITE_JOB_ID \
    --env BUILDKITE_BUILD_URL \
    --entrypoint /bin/bash \
    "$BABSG_DOCKER_URL:$BUILD_VERSION" \
    -c "
    curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter && chmod +x ./cc-test-reporter;
    ./cc-test-reporter before-build;
    python -m unittest discover -s ./tests -p '*_test.py';
    ./cc-test-reporter before-build after-build --exit-code $?;"

  echo '👌 Tests passed! :godmode:'
}

rspec() {
  set -euo pipefail

  echo "--- :docker::rspec: testing :hurtrealbad:"
  docker run \
  --rm \
  --env CODECLIMATE_REPO_TOKEN \
  --env CC_TEST_REPORTER_ID \
  --env BUILDKITE_BRANCH \
  --env BUILDKITE_COMMIT \
  --env BUILDKITE \
  --env BUILDKITE_JOB_ID \
  --env BUILDKITE_BUILD_URL \
  --entrypoint /bin/bash \
    "$BABSG_DOCKER_URL:$BUILD_VERSION" \
    -c "
    curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter && chmod +x ./cc-test-reporter;
    ./cc-test-reporter before-build;
    bundle exec rake spec;
    ./cc-test-reporter before-build after-build --exit-code $?;"
  echo '👌 Tests passed! :godmode:'
}

rubocop() {
  set -euo pipefail

  echo "--- :docker::rubocop: linting :face_punch:"
  docker run --rm --entrypoint /bin/bash \
    "$BABSG_DOCKER_URL:$BUILD_VERSION" \
    -c 'bundle exec rubocop'

  echo '👌 Looks good to me! :godmode:'
}

yardoc() {
  set -euo pipefail

  echo "--- :docker::books: docs :face_punch:"
  docker run --rm --entrypoint /bin/bash \
    "$BABSG_DOCKER_URL:$BUILD_VERSION" \
    -c 'bundle exec yard stats --list-undoc'

  echo '👌 Looks good to me! :godmode:'
}

# first arg is the command
unset COMMAND
case $1 in
  build)              COMMAND=build;;
  codeclimate)        COMMAND=codeclimate;;
  pyunittest)         COMMAND=pyunittest;;
  rspec)              COMMAND=rspec;;
  rubocop)            COMMAND=rubocop;;
  yardoc)             COMMAND=yardoc;;
  help | -h | --help) COMMAND=usage;;
  # catch borked commands
  *) echo "BORK BORK BORK"; usage; exit 1;;
esac
shift

$COMMAND "$@"
