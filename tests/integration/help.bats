#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

@test "help is ok" {
    run "$AVAKAS" help
    [ "$status" -eq 0 ]
}