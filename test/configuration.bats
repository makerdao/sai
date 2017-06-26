#!/usr/bin/env bats

load fail_if_not_on_kovan

@test "updating and getting the debt ceiling [sai cork, sai hat]" {
  sai cork 120000.0
  [ "$(sai hat)" == "120000.000000000000000000" ]
}

@test "updating and getting the liquidation ratio and the liquidation penalty [sai chop, sai cuff, sai mat, sai axe]" {
  sai chop 100.0
  sai cuff 100.0
  [ "$(sai mat)" == "100.000000000000000000000000000" ]
  [ "$(sai axe)" == "100.000000000000000000000000000" ]

  sai cuff 150.0
  sai chop 120.0
  [ "$(sai mat)" == "150.000000000000000000000000000" ]
  [ "$(sai axe)" == "120.000000000000000000000000000" ]
}

@test "updating and getting the stability fee [sai crop, sai tax]" {
  sai crop 1.0
  [ "$(sai tax)" == "1.000000000000000000000000000" ]

  sai crop 1.000000000000015
  [ "$(sai tax)" == "1.000000000000015000000000000" ]
}

@test "updating and getting the holder fee [sai coax, sai way]" {
  sai coax 1.0
  [ "$(sai way)" == "1.000000000000000000000000000" ]

  sai coax 1.00000000000028
  [ "$(sai way)" == "1.000000000000280000000000000" ]
}
