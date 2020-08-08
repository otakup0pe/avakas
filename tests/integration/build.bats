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

@test "show a (circleci) build version (git only + build number in build component)" {
    export CIRCLE_BUILD_NUM=1
    avakas_wrapper show "$REPO" --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}.1" ]
    unset CIRCLE_BUILD_NUM
}

@test "show a (gha) build version (git only + build number in build component)" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    avakas_wrapper show "$REPO" --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}.abcd.1" ]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "show a build version (git only in build component with preexisting build component)" {
    template_skeleton "$REPO" plain "0.0.1+1"
    avakas_wrapper show "$REPO" --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+1.${REV}" ]
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
    [ "$output" == "0.0.1-1.${REV}" ]
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

@test "show a (circleci) build version (git only + build number in prerelease component)" {
    export CIRCLE_BUILD_NUM=1
    avakas_wrapper show "$REPO" --pre-build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-${REV}.1" ]
    unset CIRCLE_BUILD_NUM
}

@test "show a (gha) build version (git only + build number in prerelease component)" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-${REV}.abcd.1" ]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}
