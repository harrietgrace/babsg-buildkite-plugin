#!/usr/bin/env bats

@test "It makes your warnings big" {
  run bkbh_deprecation_warning "Danger"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ":rage1:" ]]
}
