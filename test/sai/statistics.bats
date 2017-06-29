#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "get the tub stage ('register') [sai reg]" {
  [[ "$(sai reg)" == "Usual" ]]
}

@test "get the amount of backing collateral [sai air]" {
  [[ "$(sai air)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the amount of skr pending liquidation [sai fog]" {
  [[ "$(sai fog)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the good debt [sai ice]" {
  [[ "$(sai fog)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the amount of surplus sai [sai joy]" {
  [[ "$(sai joy)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the amount of raw collateral [sai pie]" {
  [[ "$(sai pie)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the amount of bad debt [sai woe]" {
  [[ "$(sai woe)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the current entry price (gem per skr) [sai per]" {
  [[ "$(sai per)" =~ [0-9]+\.[0-9]{27} ]]
}

@test "get the reference price (ref per skr) [sai tag]" {
  [[ "$(sai tag)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the internal debt price [sai chi]" {
  [[ "$(sai chi)" =~ [0-9]+\.[0-9]{27} ]]
}

@test "get the accrued holder fee [sai par]" {
  [[ "$(sai par)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the skr per sai rate (for boom and bust) [sai s2s]" {
  [[ "$(sai s2s)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the price of skr in sai for boom [sai bid]" {
  [[ "$(sai bid)" =~ [0-9]+\.[0-9]{18} ]]
}

@test "get the price of skr in sai for bust [sai ask]" {
  [[ "$(sai ask)" =~ [0-9]+\.[0-9]{18} ]]
}

