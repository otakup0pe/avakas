#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" plain "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    rm -rf "$REPO_ORIGIN" "$REPO"
}

@test "set a plain version" {
    run avakas_wrapper set "$REPO" "0.0.2"
    echo "${lines[@]}"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "Version set to 0.0.2" ]
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "0.0.2" ]
}

@test "show a plain version" {
    run avakas_wrapper show "$REPO"

    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "0.0.1" ]
}

@test "bump a plain version - patch" {
    run avakas_wrapper bump "$REPO" patch
    echo "${lines[@]}"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "Version updated from 0.0.1 to 0.0.2" ]
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "0.0.2" ]
}

@test "bump a plain version - minor" {
    run avakas_wrapper bump "$REPO" minor
    echo "${lines[@]}"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "Version updated from 0.0.1 to 0.1.0" ]
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "0.1.0" ]
}

@test "bump a plain version - major" {
    run avakas_wrapper bump "$REPO" major
    echo "${lines[@]}"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "Version updated from 0.0.1 to 1.0.0" ]
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "${lines[1]}" == "1.0.0" ]
}

