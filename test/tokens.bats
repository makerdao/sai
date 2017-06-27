#!/usr/bin/env bats

load fail_if_not_on_kovan

@test "get the gem token [sai gem]" {
  [[ "$(sai gem)" == 0x* ]]
}

@test "get the skr token [sai skr]" {
  [[ "$(sai skr)" == 0x* ]]
}

@test "get the sai token [sai sai]" {
  [[ "$(sai sai)" == 0x* ]]
}

@test "get the sin token [sai sin]" {
  [[ "$(sai sin)" == 0x* ]]
}
