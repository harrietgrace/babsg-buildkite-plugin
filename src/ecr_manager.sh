#!/bin/bash

#------------------------------------------------------------
# ECR Manager
#------------------------------------------------------------

# A unique container is built every time a commit is pushed to the git repo.
# This clogs up our ECR.
#
# So, every time a build finishes, we should delete the $BUILD_VERSION tag. If
# you delete the last tag from a container in ECR, it goes 💥
#
# If we want to actually use the container, we need to add new tags first.

# RTFM
usage() {
  cat <<RTFM

Usage: ecr_manager [options]

Options:
  -h display this message
  -b build and push a docker container
  -c perform full buildkite cleanup
  -d steps to run a base container build script
  -s display stats about your repo
  -t tag mode
  -u untag mode
  --build-version=<str> the build version slug for tagging
  --image-tags=<str>    a list of tags to apply
  --python2             add a pip cache step before building
  --repo-url=<str>      the ECR docker repo URL
RTFM
}

# Set defaults for optional variables
set_defaults() {
  # note: docker commands use the REPO_URL, aws cli commands use the REPO SLUG
  REPO_URL="${REPO_URL:-$BABSG_DOCKER_URL}"
  if [ "$REPO_URL" == "" ]; then
    echo "You need to provide a repo with --repo-url"
    exit 1
  fi
  REPO_SLUG=$(echo "$REPO_URL" | cut -d "/" -f 2)
  # we need to know the docker region for our command
  REGION=$(echo "$REPO_URL" | cut -d "." -f 4)
}

# @todo namespace prehook exports, remove support for other shit

main() {
  case "$MODE" in
    usage) usage; exit;;
  esac

  set_defaults

  case "$MODE" in
    build)      build;        exit;;
    cleanup)    cleanup;      exit;;
    dockerbase) dockerbase;   exit;;
    release)    release;      exit;;
    stats)      stats;        exit;;
    tag)        tag;          exit;;
    untag)      untag;        exit;;
    *)          stats;        exit;;
  esac
}

# build and push to ECR
build() {
  set -e

  if [[ "$BUILD_PYTHON2" == "true" ]]; then
    echo "--- :docker: :python: :construction_worker: Building PIP Cache";
    mkdir pip-cache
    docker run --rm -v $(pwd):/build \
      -v /var/lib/buildkite-agent/.ssh/known_hosts:/root/.ssh/known_hosts:ro \
      -v $(dirname $SSH_AUTH_SOCK):$(dirname $SSH_AUTH_SOCK) \
      -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
      -w /build --entrypoint pip python:2 \
      download -d pip-cache --process-dependency-links \
      .
  fi

  echo "--- :docker: building container"
  docker build -t app .
  echo "--- :docker: pushing to :aws:"
  docker tag app "$REPO_URL:$BUILD_VERSION"
  docker push "$REPO_URL:$BUILD_VERSION"

  set +e
}

cleanup() {
  echo "--- :aws: ensuring we have the image locally"
  docker pull "$REPO_URL:$BUILD_VERSION"
  if [[ "$BABSG_RUNTIME_ENV" == 'production' ]] ||
     [[ "$BABSG_RUNTIME_ENV" == 'staging' ]] &&
     [[ "$BUILDKITE_COMMAND_EXIT_STATUS" -eq 0 ]]; then
    tag
  fi
  untag
  stats
}

# steps used for building base docker containers
dockerbase() {
  build
  tag
  untag
  stats
}

# enfore single mode
esm() {
  if [[ -n "$MODE" ]]; then echo "BORK BORK BORK BORK"; exit 1; fi
}

# push containers as git tags and then clean up the current tag
release() {
  set -e
  if [[ "$BUILDKITE_TAG" != "" ]]; then
    echo "--- :ecr: releasing version $BUILDKITE_TAG :dart:"
    docker pull "$REPO_URL:$BUILD_VERSION"
    docker tag "$REPO_URL:$BUILD_VERSION" "$REPO_URL:$BUILDKITE_TAG"
    docker push "$REPO_URL:$BUILDKITE_TAG"
  fi
  set +e
  cleanup
}

# print some stats about the repo!
stats() {
  set -e
  IMAGES=$(aws ecr describe-images --repository "$REPO_SLUG" --region "$REGION")
  COUNT=$(echo "$IMAGES" | jq '.imageDetails | length' )
  if [ "$COUNT" -eq 0 ]; then echo "$REPO_SLUG is empty"; return; fi
  RAW_BYTES=$(echo "$IMAGES" | jq '.imageDetails[].imageSizeInBytes' | paste -sd+ - | bc)
  BYTES=$(echo "$RAW_BYTES" | awk '{ split( "KB MB GB TB PB EB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1) v[s] }')
  COST=$(printf "%.2f" "$(echo "$RAW_BYTES * 0.0000000001" | bc)")
  COUNT=$(echo "$IMAGES" | jq '.imageDetails | length' )
  echo "--- $REPO_SLUG costs \$$COST/month" \
       "and contains $COUNT containers ($BYTES)"
  set +e
}

tag() {
  # if tags are specified, tag them, otherwise tag a couple of defaults
  if [ -n "$IMAGE_TAGS" ]; then
    MY_TAGS="${IMAGE_TAGS//,/ }"
  else
    MY_TAGS="$BABSG_RUNTIME_ENV $BABSG_RUNTIME_ENV-$BUILD_VERSION"
  fi
  docker pull "$REPO_URL:$BUILD_VERSION"
  echo "-- :aws: tagging $MY_TAGS"
  for T in $MY_TAGS; do
    docker tag "$REPO_URL:$BUILD_VERSION" "$REPO_URL:$T"
    docker push "$REPO_URL:$T"
  done
}

untag() {
  # if tags are specified, untag them, otherwise untag build version
  if [ -n "$IMAGE_TAGS" ]; then
    IDS="imageTag=${IMAGE_TAGS//,/,imageTag=}"
  else
    IDS="imageTag=$BUILD_VERSION"
  fi
  echo "--- :aws: untagging $IDS"
  aws ecr batch-delete-image \
    --region "$REGION" \
    --repository-name "$REPO_SLUG" \
    --image-ids "$IDS"
}

# we love arg parsing
unset MODE
while [ "$1" != "" ]; do
  KEY=$(echo "$1" | awk -F= '{print $1}')
  VALUE=$(echo "$1" | awk -F= '{print $2}')
  case $KEY in
    # HELP! (I need somebody)
    -h | --help) MODE=usage;;
    # choose one
    -b)          esm; MODE=build;;
    -c)          esm; MODE=cleanup;;
    -d)          esm; MODE=dockerbase;;
    -r)          esm; MODE=release;;
    -s)          esm; MODE=stats;;
    -t)          esm; MODE=tag;;
    -u)          esm; MODE=untag;;
    # config stuff
    --build-version)  BUILD_VERSION=$VALUE;;
    --image-tags)     IMAGE_TAGS=$VALUE;;
    --python2)        BUILD_PYTHON2=true;;
    --repo-url)       REPO_URL=$VALUE;;
    # catch borked options
    *)           echo "BORK BORK BORK"; usage; exit 1;;
  esac
  shift
done

main
