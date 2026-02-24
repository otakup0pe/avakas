#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" pep621 "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show a pep621 version" {
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1" ]
}

@test "show a pep621 version with explicit flavor" {
    avakas_wrapper show "$REPO" --flavor pep621
    [ "$output" == "0.0.1" ]
}

@test "set a pep621 version" {
    avakas_wrapper set "$REPO" "0.0.2"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "bump a pep621 version - patch" {
    avakas_wrapper bump "$REPO" patch
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "bump a pep621 version - minor" {
    avakas_wrapper bump "$REPO" minor
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.1.0" ]
}

@test "bump a pep621 version - major" {
    avakas_wrapper bump "$REPO" major
    scan_lines "Version updated from 0.0.1 to 1.0.0" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "1.0.0" ]
}
