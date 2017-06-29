#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "print help about sai(1) or one of its subcommands [sai help]" {
  sai
  sai help
  sai help axe
}
