#!/usr/bin/env bats

setup() {
  NAME=$(aws elasticbeanstalk describe-environments --region ap-southeast-2 | jq -r '.Environments[0].EnvironmentName')
  if [[ "$NAME" == "null" ]] || [[ "$NAME" == "" ]]; then
    echo "--- :rage1::rage2::rage3::rage4: No available :elasticbeanstalk: environments. Skipping tests :rage4::rage3::rage2::rage1:"
    skip
  fi
}

@test "Has a help option" {
  run elastic_beanstalk_environment_status -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "Tells you environment color" {
  run elastic_beanstalk_environment_status -c --name=$NAME
  [ "$status" -eq 0 ]
  [[ "$output" == "Green"  ]] ||
  [[ "$output" == "Grey"   ]] ||
  [[ "$output" == "Red"    ]] ||
  [[ "$output" == "Yellow" ]]
}

@test "Tells you environment status" {
  run elastic_beanstalk_environment_status -s --name=$NAME
  [ "$status" -eq 0 ]
  [[ "$output" == "Ready" ]] ||
  [[ "$output" == "Ready" ]] ||
  [[ "$output" == "Ready" ]]
}

@test "Tells you environment version" {
  run elastic_beanstalk_environment_status -v --name=$NAME
  [ "$status" -eq 0 ]
}
