#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    REPO_ORIGIN=$(fake_repo)
    plain_version "$REPO_ORIGIN" "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    rm -rf "$REPO_ORIGIN" "$REPO"
}

avakas_wrapper() {
    "$AVAKAS" $* 2> /dev/null
}

@test "show a version" {
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "0.0.1" ]
}

@test "set a version" {
    run avakas_wrapper set "$REPO" "0.0.2"
    echo "${lines[@]}"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "Version set to 0.0.2" ]
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "0.0.2" ]
}
