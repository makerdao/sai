#!/usr/bin/env bats

load fail_if_not_on_kovan

@test "get the jug-like sin tracker (DSDevil) [sai dev]" {
  [[ "$(sai dev)" == 0x* ]]
}

@test "get the collateral vault [sai jar]" {
  [[ "$(sai jar)" == 0x* ]]
}

@test "get the good debt vault [sai pot]" {
  [[ "$(sai pot)" == 0x* ]]
}

@test "get the liquidator vault [sai pit]" {
  [[ "$(sai pit)" == 0x* ]]
}

@test "get the target price engine [sai tip]" {
  [[ "$(sai tip)" == 0x* ]]
}

@test "get the gem price feed [sai pip]" {
  [[ "$(sai pip)" == 0x* ]]
}

