#!/usr/bin/env bats

load ../fail_if_not_on_kovan

@test "print help about sai-lpc(1) or one of its subcommands [sai-lpc help]" {
  sai-lpc
  sai-lpc help
  sai-lpc help ref
}
