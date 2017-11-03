# #!/usr/bin/env bats

setup() {
  ROLE=$(aws iam list-roles | jq -r '.Roles[] | select(.RoleName == "view-only-access") | .Arn')
}

@test "Can assume a role" {
  $(assume_iam_role --role=$ROLE)
  [ -n $AWS_ACCESS_KEY_ID ]
  [ -n $AWS_SECRET_ACCESS_KEY ]
  [ -n $AWS_SESSION_TOKEN ]
  [ -n $AWS_EXPIRATION ]
}

@test "Can unassume a role" {
  echo $AWS_SESSION_TOKEN
  $(assume_iam_role --role=$ROLE)
  run assume_iam_role -u
  [ "$status" -eq 0 ]
  [ -z $AWS_ACCESS_KEY_ID ]
  [ -z $AWS_SECRET_ACCESS_KEY ]
  [ -z $AWS_SESSION_TOKEN ]
  [ -z $AWS_EXPIRATION ]
}
