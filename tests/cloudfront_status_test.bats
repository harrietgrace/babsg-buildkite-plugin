#!/usr/bin/env bats

setup() {
  # AWS CLI support for this service is only available in a preview stage.
  aws configure set preview.cloudfront true
  ID=$(aws cloudfront list-distributions | jq -r '.DistributionList.Items[0].Id')
  if [[ "$ID" == "null" ]] || [[ "$ID" == "" ]]; then
    echo "--- :rage1::rage2::rage3::rage4: No available :cloudfront: distributions. Skipping tests :rage4::rage3::rage2::rage1:"
    skip
  fi
}

@test "Has a help option" {
  run cloudfront_status -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "Gives you a nice output" {
  run cloudfront_status --distro=$ID
  [ "$status" -eq 0 ]
  [[ "$output" =~ "--- :barely_sunny:" ]]
}

@test "Tells you the status" {
  run cloudfront_status --distro=$ID -s
  [ "$status" -eq 0 ]
  [[ "$output" == "Completed" ]] ||
  [[ "$output" == "Incomplete" ]]
}
