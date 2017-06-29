#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "recalculate the internal debt price, get the time of last drip [sai drop, sai rho]" {
  rho_before=$(sai rho)
  sai drip
  rho_after=$(sai rho)

  [[ "$rho_after" -gt "$rho_before" ]]
}

@test "recalculate the accrued holder fee (par), get the time of last prod [sai prod, sai tau]" {
  tau_before=$(sai tau)
  sai prod
  tau_after=$(sai tau)

  [[ "$tau_after" -gt "$tau_before" ]]
}

