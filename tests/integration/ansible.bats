#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" ansible "v0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show a ansible version" {
    avakas_wrapper show "$REPO"
    scan_lines "0.0.1" "${lines[@]}"
}

@test "set an ansible version" {
    avakas_wrapper set "$REPO" "0.0.2"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    scan_lines "0.0.2" "${lines[@]}"
    [ ! -e "$REPO/version" ]
}

@test "bump an ansible version" {
    avakas_wrapper bump "$REPO" patch
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    scan_lines "0.0.2" "${lines[@]}"
    [ ! -e "$REPO/version" ]
}

@test "do not allow the setting of a prefix" {
    avakas_rc 1 show "$REPO" --tag-prefix aaa
    scan_lines "Problem: Cannot specify a tag prefix with an Ansible Role" "${lines[@]}"
}

