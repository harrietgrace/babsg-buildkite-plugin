#!/bin/bash

# RTFM
usage() {
  cat <<RTFM

Usage: cloudfront_status [options]

If no options are specified, outputs a human-readable cloudfront status

Options:
  -h display this message
  --distro=<str> the cloudfront distribution identifier
RTFM
}

main() {
  case $MODE in
    usage) usage; exit;;
  esac

  # AWS CLI support for this service is only available in a preview stage.
  aws configure set preview.cloudfront true

  refresh_cloudfront_state

  case $MODE in
    complete)    wait_for status Completed; exit;;
    create_time) create_time;               exit;;
    status)      status;                    exit;;
    *)           print_status;              exit;;
  esac
}

create_time() {
    echo "$HEALTH" | jq -r '.InvalidationList.Items[0].CreateTime'
}

# enfore single mode
esm() {
  if [[ -n $MODE ]]; then echo "BORK BORK BORK BORK"; exit 1; fi
}

print_status() {
  echo "--- :barely_sunny: Invalidation status: $(status)"
}

refresh_cloudfront_state() {
  HEALTH=$(aws cloudfront list-invalidations \
             --max-items 1 \
             --distribution-id "$DISTRO")
}

status() {
  echo "$HEALTH" | jq -r '.InvalidationList.Items[0].Status'
}

wait_for() {
  # start the clock
  SECONDS=0
  echo "[$SECONDS s] $(print_status)"
  while [[ $($1) != "$2" ]]; do
    if [[ $(status) == "Completed" ]]; then
      echo "--- [ERROR] Environment is stable but $1 is not $2"; exit 1
    fi
    echo -n "[$SECONDS s] "
    print_status
    sleep "$TIMEOUT"
    refresh_cloudfront_state
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
    -s)          esm; MODE=status;;
    -t)          esm; MODE=create_time;;
    # wait options
    -C)          esm; MODE=complete;;
    # config stuff
    --distro)    DISTRO=$VALUE;;
    # catch borked options
    *)           echo "BORK BORK BORK"; usage; exit 1;;
  esac
  shift
done

main
