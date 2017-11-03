#!/bin/bash

# AWS assume role helper

# RTFM
usage() {
  cat <<RTFM

Usage: \$(assume_iam_role arn)
       note: command subsitution is required since you are setting ENVs
Options:
  -h display this message
  -u unassume the role
  --role=<str> the ARN of the role to assume
RTFM
}

main() {
  case $MODE in
    usage)    usage;    exit;;
    unassume) unassume; exit;;
    *)        assume  ; exit;;
  esac
}

assume() {
  CREDS=$(aws sts assume-role \
            --output json \
            --role-arn "$ROLE" \
            --role-session-name deploy)
  AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r ".Credentials.AccessKeyId")
  AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r ".Credentials.SecretAccessKey")
  AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r ".Credentials.SessionToken")
  AWS_EXPIRATION=$(echo "$CREDS" | jq -r ".Credentials.Expiration")
  echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
  echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
  echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
  echo "export AWS_EXPIRATION=$AWS_EXPIRATION"
}

unassume() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_EXPIRATION
}

# we love arg parsing
unset MODE
while [ "$1" != "" ]; do
  KEY=$(echo "$1" | awk -F= '{print $1}')
  VALUE=$(echo "$1" | awk -F= '{print $2}')
  case $KEY in
    # HELP! (I need somebody)
    -h | --help) MODE=usage;;
    -u)          MODE=unassume;;
    # config stuff
    --role)      ROLE=$VALUE;;
    # catch borked options
    *)           echo "BORK BORK BORK"; MODE=usage; exit 1;;
  esac
  shift
done

main
