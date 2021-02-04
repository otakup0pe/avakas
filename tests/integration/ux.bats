#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
}

teardown() {
    shared_teardown
}

@test "can show version" {
    avakas_rc 0 version
    scan_lines "avakas v.+" "${lines[@]}"
}

@test "help is ok" {
    avakas_rc 0 help
    scan_lines "usage: avakas.+" "${lines[@]}"
    avakas_rc 0 --help
    scan_lines "usage: avakas.+" "${lines[@]}"
    avakas_rc 0 -h
    scan_lines "usage: avakas.+" "${lines[@]}"
}

@test "unexpected help is also ok" {
    avakas_rc 1
    scan_lines "usage: avakas.+" "${lines[@]}"
    avakas_rc 2 not-a-real-command
    scan_lines "usage: avakas.+" "${lines[@]}"
}
