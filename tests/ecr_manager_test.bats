#!/usr/bin/env bats

setup() {
  DOCKER_REPO=$(aws ecr describe-repositories --region ap-southeast-2 | jq -r '.repositories[0].repositoryArn')
  if [[ "$DOCKER_REPO" == "null" ]] || [[ "$DOCKER_REPO" == "" ]]; then
    echo "--- :rage1::rage2::rage3::rage4: No available :docker: repos. Skipping tests :rage4::rage3::rage2::rage1:"
    skip
  fi
}

@test "Has a help option" {
  run ecr_manager -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "Gives you stats" {
  run ecr_manager -s --repo-url=$DOCKER_REPO
  echo $output
  [ "$status" -eq 0 ]
  [[ "$output" =~ "empty" ]] ||
  [[ "$output" =~ "costs" ]]
}
