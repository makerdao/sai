#!/usr/bin/env bats

load fail_if_not_on_kovan

@test "get the amount of backing collateral [sai air]" {
  [[ "$(sai air)" =~ [0-9]+\.[0-9]+ ]]
}

@test "get the amount of skr pending liquidation [sai fog]" {
  [[ "$(sai fog)" =~ [0-9]+\.[0-9]+ ]]
}

@test "get the good debt [sai ice]" {
  [[ "$(sai fog)" =~ [0-9]+\.[0-9]+ ]]
}

@test "get the amount of surplus sai [sai joy]" {
  [[ "$(sai joy)" =~ [0-9]+\.[0-9]+ ]]
}

@test "get the amount of raw collateral [sai pie]" {
  [[ "$(sai pie)" =~ [0-9]+\.[0-9]+ ]]
}

@test "get the amount of bad debt [sai woe]" {
  [[ "$(sai woe)" =~ [0-9]+\.[0-9]+ ]]
}

