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

@test "show a build version (git only)" {
    run avakas_wrapper show "$REPO" --build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO_ORIGIN)
    scan_lines "0.0.1+${REV}" "${lines[@]}"
}

@test "show a build version (git only + build number)" {
    export BUILD_NUMBER=1
    run avakas_wrapper show "$REPO" --build
    unset BUILD_NUMBER
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO_ORIGIN)
    scan_lines "0.0.1+${REV}.1" "${lines[@]}"
}

@test "bump a plain version - patch to patch" {
    run avakas_wrapper bump "$REPO" patch
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.0.2" "${lines[@]}"
}

@test "bump a plain version - patch to minor" {
    run avakas_wrapper bump "$REPO" minor
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.1.0" "${lines[@]}"
}

@test "bump a plain version - patch to major" {
    run avakas_wrapper bump "$REPO" major
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "1.0.0" "${lines[@]}"
}

@test "bump a plain version - patch to prerelease" {
    run avakas_wrapper bump "$REPO" pre
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.0.1-1"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    scan_lines "0.0.1-1" "${lines[@]}"

}
