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

@test "set build metadata (git only in build component)" {
    REV=$(current_rev $REPO)
    avakas_wrapper set "$REPO" "0.0.2" --build-meta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2+${REV}" ]
}

@test "set jenkins sourced build metadata (git only + build number in build component)" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper set "$REPO" "0.0.2" --build-meta
    unset BUILD_NUMBER
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2+${REV}.1" ]
}

@test "set travis-sourced build metadata (git only + build number in build component)" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper set "$REPO" "0.0.2" --build-meta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2+${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "set circleci-sourced build metadata (git only + build number in build component)" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper set "$REPO" "0.0.2" --build-meta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2+${REV}.1" ]
    unset CIRCLE_BUILD_NUM
}

@test "set github-actions-sourced build metadata (git only + build number in build component)" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper set "$REPO" "0.0.2" --build-meta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2+${REV}.abcd.1" ]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "set build metadata (override existing build components with preexisting build component)" {
    template_skeleton "$REPO" plain "0.0.2+1"
    REV=$(current_rev $REPO)
    avakas_wrapper set "$REPO" "0.0.2" --build-meta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2+${REV}" ]
}
