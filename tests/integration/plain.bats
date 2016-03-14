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
    [ "$status" -eq 0 ]
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.0.2" "${lines[@]}"
}

@test "show a plain version" {
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.0.1" "${lines[@]}"
}

@test "bump a plain version - patch" {
    run avakas_wrapper bump "$REPO" patch
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.0.2" "${lines[@]}"
}

@test "bump a plain version - minor" {
    run avakas_wrapper bump "$REPO" minor
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.1.0" "${lines[@]}"
}

@test "bump a plain version - major" {
    run avakas_wrapper bump "$REPO" major
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "1.0.0" "${lines[@]}"
}

