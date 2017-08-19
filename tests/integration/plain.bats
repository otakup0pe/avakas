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
    avakas_wrapper set "$REPO" "0.0.2"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "show a plain version" {
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1" ]
}

@test "show a build version (git only in build component)" {
    avakas_wrapper show "$REPO" --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}" ]
}

@test "show a (jenkins) build version (git only + build number in build component)" {
    export BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --build
    unset BUILD_NUMBER
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}.1" ]
}

@test "show a (travis) build version (git only + build number in build component)" {
    export TRAVIS_BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "show a build version (git only in build component with preexisting build component)" {
    template_skeleton "$REPO" plain "0.0.1+1"
    avakas_wrapper show "$REPO" --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+1."$REV ]
}

@test "show a build version (git only in prerelease component)" {
    avakas_wrapper show "$REPO" --pre-build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-${REV}" ]
}

@test "show a build version (git only in prerelease component with preexisting prerelease component)" {
    template_skeleton "$REPO" plain 0.0.1-1
    avakas_wrapper show "$REPO" --pre-build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-1."$REV ]
}

@test "show a (jenkins) build version (git only + build number in prerelease component)" {
    export BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build
    unset BUILD_NUMBER
    REV=$(current_rev $REPO_ORIGIN)
    [ "$output" == "0.0.1-${REV}.1" ]
}

@test "show a (travis) build version (git only + build number in prerelease component)" {
    export TRAVIS_BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build
    REV=$(current_rev $REPO_ORIGIN)
    [ "$output" == "0.0.1-${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "bump a plain version - patch to patch" {
    avakas_wrapper bump "$REPO" patch
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "bump a plain version - patch to minor" {
    avakas_wrapper bump "$REPO" minor
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.1.0" ]
}

@test "bump a plain version - patch to major" {
    avakas_wrapper bump "$REPO" major
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "1.0.0" ]
}

@test "bump a plain version - patch to prerelease" {
    avakas_wrapper bump "$REPO" pre
    scan_lines "Version updated from 0.0.1 to 0.0.1-1"  "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-1" ]

}

@test "show a plain version - specified filename" {
    plain_version "$REPO" "0.0.1-1" "foo"
    avakas_wrapper show "$REPO" --filename "foo"
    [ "$output" == "0.0.1-1" ]
}

@test "set a plain version - specified filename" {
    plain_version "$REPO" "0.0.1-1" "foo"
    avakas_wrapper set "$REPO" "0.0.2" --filename "foo"
    avakas_wrapper show "$REPO" --filename "foo"
    [ "$output" == "0.0.2" ]
}

@test "bump a plain version - patch->patch, specified filename" {
    plain_version "$REPO" "0.0.2" "foo"
    avakas_wrapper bump "$REPO" "patch" --filename "foo"
    avakas_wrapper show "$REPO" --filename "foo"
    [ "$output" == "0.0.3" ]
}
