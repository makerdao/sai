#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "get the jug-like sin tracker (DSDevil) [sai dev]" {
  [[ "$(sai dev)" == "$SAI_DEV" ]]
}

@test "get the collateral vault [sai jar]" {
  [[ "$(sai jar)" == "$SAI_JAR" ]]
}

@test "get the good debt vault [sai pot]" {
  [[ "$(sai pot)" == "$SAI_POT" ]]
}

@test "get the liquidator vault [sai pit]" {
  [[ "$(sai pit)" == "$SAI_PIT" ]]
}

@test "get the target price engine [sai tip]" {
  [[ "$(sai tip)" == "$SAI_TIP" ]]
}

@test "get the gem price feed [sai pip]" {
  [[ "$(sai pip)" == "$SAI_PIP" ]]
}
