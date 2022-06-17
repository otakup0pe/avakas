#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" cookbook "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show a cookbook version" {
    avakas_wrapper show "$REPO"
    scan_lines "0.0.1" "${lines[@]}"
}

@test "set a cookbook version" {
    avakas_wrapper set "$REPO" "0.0.2"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    scan_lines "0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "bump a cookbook version" {
    avakas_wrapper bump "$REPO" patch
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    scan_lines "0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}
