#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
}

teardown() {
    shared_teardown
}

@test "help is ok" {
    avakas_wrapper help
}
