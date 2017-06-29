#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "create a new cup, get the last cup id, list cups created by you [sai open, sai cupi, sai cups]" {
  cupi_before="$(sai cupi)"
  cups_before="$(sai cups)"
  cups_before_count=$(echo "$cups_before" | wc -l | tr -d '[:space:]')

  sai open

  cupi_after="$(sai cupi)"
  cups_after="$(sai cups)"
  cups_after_count=$(echo "$cups_after" | wc -l | tr -d '[:space:]')

  [[ "$cupi_after" -eq "$((cupi_before+1))" ]]
  [[ "$cups_after_count" -eq "$((cups_before_count+1))" ]]
}

@test "show the cup info [sai cup]" {
  sai open; cup_id=$(sai cupi)

  [[ "$(sai --cup="$cup_id" cup | wc -l | tr -d '[:space:]')" -eq 3 ]]
}

@test "get the amount of skr collateral locked in a cup, get the amount of debt in a cup [sai ink, sai tab]" {
  sai open; cup_id=$(sai cupi)

  [[ "$(sai --cup="$cup_id" ink)" =~ [0-9]+\.[0-9]+ ]]
  [[ "$(sai --cup="$cup_id" tab)" =~ [0-9]+\.[0-9]+ ]]
}

@test "determine if a cup is safe [sai safe]" {
  sai open; cup_id=$(sai cupi)

  [[ "$(sai --cup="$cup_id" safe)" == "true" ]]
}

@test "transfer ownership of a cup, get the owner of a cup [sai give, sai lad]" {
  sai open; cup_id=$(sai cupi)

  other_address="0xb7cceff108235e3da7b2aa55921c788366895fe3"

  [[ "$(sai --cup="$cup_id" lad)" == "$ETH_FROM" ]]
  sai --cup="$cup_id" give "$other_address"
  [[ "$(sai --cup="$cup_id" lad)" == "$other_address" ]]
}

@test "close a cup [sai shut]" {
  sai open; cup_id=$(sai cupi)

  sai --cup="$cup_id" shut
  [[ "$(sai --cup="$cup_id" lad)" == "0x0000000000000000000000000000000000000000" ]]
}

