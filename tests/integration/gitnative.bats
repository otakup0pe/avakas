#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" plain "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show a git-native version" {
    avakas_wrapper show "$REPO" --flavor "git-native"
    scan_lines "0.0.1" "${lines[@]}"
    [ -e "$REPO/version" ]
}

@test "set an git-native version" {
    avakas_wrapper set "$REPO" "0.0.2" --flavor "git-native"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    scan_lines "0.0.2" "${lines[@]}"
    [ ! -e "$REPO/version" ]
}

@test "bump an git-native version" {
    avakas_wrapper bump "$REPO" patch --flavor "git-native"
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    scan_lines "0.0.2" "${lines[@]}"
    [ -e "$REPO/version" ]
}
