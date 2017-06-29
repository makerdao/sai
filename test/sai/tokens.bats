#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "get the gem token [sai gem]" {
  [[ "$(sai gem)" == "$SAI_GEM" ]]
}

@test "get the skr token [sai skr]" {
  [[ "$(sai skr)" == "$SAI_SKR" ]]
}

@test "get the sai token [sai sai]" {
  [[ "$(sai sai)" == "$SAI_SAI" ]]
}

@test "get the sin token [sai sin]" {
  [[ "$(sai sin)" == "$SAI_SIN" ]]
}
