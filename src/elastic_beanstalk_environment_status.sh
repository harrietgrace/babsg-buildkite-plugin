#!/bin/bash

# Elastic Beanstalk environment status
#
# Gives you some sweet information about your EB environment. This is the
# function that kicked off BKBH.

# RTFM
usage() {
  echo -e ""
  echo -e "Usage: elastic_beanstalk_environment_status [options]"
  echo -e ""
  echo -e "If no options are specified, outputs a human-readable environment status"
  echo -e ""
  echo -e "Options:"
  echo -e "\\t-h display this message"
  echo -e "\\t-c output the environment color"
  echo -e "\\t-s output the environment status"
  echo -e "\\t-v output the environment version"
  echo -e "\\t-G spam aws until the environment goes green"
  echo -e "\\t-R spam aws until the environment is ready"
  echo -e "\\t--name=<str> the name of the elastic beanstalk environment"
  echo -e "\\t--region=<str> the AWS region"
  echo -e "\\t--timeout=<int> time to wait before giving up on spamming AWS"
  echo -e "\\t--verify=<str> verify that the given version is in fact running"
  echo -e "\\t    (defaults to \$PLATFORM-\$APPLICATION-\$RUNTIME_ENV)"
}

# Set defaults for optional variables
set_defaults() {
  NAME=${NAME:-"$BABSG_ELASTIC_BEANSTALK_ENV_NAME"}
  # try hard to get a region
  REGION=${REGION:-${DEPLOY_AWS_REGION:-${AWS_REGION:-"ap-southeast-2"}}}
  TIMEOUT=${TIMEOUT:-20}
}

main() {
  case $MODE in
    usage) usage; exit;;
  esac

  set_defaults

  refresh_environment_state

  ensure_environment_is_unique

  case $MODE in
    color) color; exit;;
    green)
      wait_for color Green; exit;;
    ready)
      wait_for status Ready; exit;;
    status) status; exit;;
    verify) verify; exit;;
    version) version; exit;;
    *) print_status; exit;;
  esac
}

color() {
  echo "$HEALTH" | jq -r '.Environments[0].Health'
}

ensure_environment_is_unique() {
  if [[ $(echo "$HEALTH" | jq '.Environments | length') -ne 1 ]]; then
    echo "--- Unique environment not discovered :japanese_goblin:"
    echo "$HEALTH" | jq '.Environments'
    exit 1
  fi
}

# enfore single mode
esm() {
  if [[ -n $MODE ]]; then echo "BORK BORK BORK BORK"; exit 1; fi
}

print_color() {
  case $(color) in
    Green) echo "$(tput setaf 2):green_heart:";;
    Grey) echo "$(tput setaf 7):sleeping:";;
    Red) echo "$(tput setaf 1):heart:";;
    Yellow) echo "$(tput setaf 3):yellow_heart:";;
    *) echo "$(tput setaf 1):broken_heart:";;
  esac
}

print_status() {
  echo "--- $(print_color) :elasticbeanstalk: $(color): $(status)$(tput sgr0)"
}

refresh_environment_state() {
  HEALTH="$(aws elasticbeanstalk describe-environments \
              --environment-name "$NAME" \
              --region "$REGION")"
}

status() {
  echo "$HEALTH" | jq -r '.Environments[0].Status'
}

verify() {
  if [[ "$VER" != $(version) ]]; then
    echo "--- [ERROR] wrong version deployed ($(version), expecting $VER)"
    exit 1
  fi
}

version() {
  echo "$HEALTH" | jq -r '.Environments[0].VersionLabel'
}

wait_for() {
  # start the clock
  SECONDS=0
  echo "[$SECONDS s] $(print_status)"
  while [[ $($1) != "$2" ]]; do
    if [[ $(status) == "Ready" ]]; then
      echo "--- [ERROR] Environment is stable but $1 is not $2"; exit 1
    fi
    echo -n "[$SECONDS s] "
    print_status
    sleep "$TIMEOUT"
    refresh_environment_state
  done
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
    ## outputs
    -c)          esm; MODE=color;;
    -s)          esm; MODE=status;;
    -v)          esm; MODE=version;;
    ## wait options
    -G)          esm; MODE=green;;
    -R)          esm; MODE=ready;;
    # config stuff
    --name)      NAME=$VALUE;;
    --region)    REGION=$VALUE;;
    --timeout)   TIMEOUT=$VALUE;;
    --verify)    esm; MODE=verify; VER=$VALUE;;
    # catch borked options
    *)           echo "BORK BORK BORK"; usage; exit 1;;
  esac
  shift
done

main
