#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" ansible "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show a ansible version" {
    run avakas_wrapper show "$REPO"

    [ "$status" -eq 0 ]
    scan_lines "0.0.1" "${lines[@]}"
}

@test "set an ansible version" {
    run avakas_wrapper set "$REPO" "0.0.2"
    echo "${lines[@]}"
    [ "$status" -eq 0 ]
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.0.2" "${lines[@]}"
}
