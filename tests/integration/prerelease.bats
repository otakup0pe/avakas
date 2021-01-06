#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" plain "0.0.0"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "set a prerelease prefix" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1" ]
}

@test "set a prerelease w/prefix and git build" {
  REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}" ]
}

@test "set a prerelease w/prefix and git (jenkins) build" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.1" ]
    unset BUILD_NUMBER
}

@test "set a prerelease w/prefix and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "set a prerelease w/prefix and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.1" ]
    unset CIRCLE_BUILD_NUM
}

@test "set a prerelease w/prefix and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.abcd.1" ]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "set a prerelease w/date" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    MATCH="$(rev <<< "$output" | cut -c 3- | rev)"
    grep -v "0.0.1\-1.${ALMOST}[0-9]{2}" <<< "$output"
}

@test "set a prerelease w/date and git build" {
  REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease  --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}" <<< "$output"
}

@test "set a prerelease w/date and git (jenkins) build" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset BUILD_NUMBER
}

@test "set a prerelease w/date and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset TRAVIS_BUILD_NUMBER
}

@test "set a prerelease w/date and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset CIRCLE_BUILD_NUM
}

@test "set a prerelease w/date and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.abc.1}" <<< "$output"
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "set a prerelease w/prefix and date" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1-alpha.${ALMOST}[0-9]{2}" <<< "$output"
}

@test "set a prerelease w/prefix and date and git build" {
  REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}" <<< "$output"
}

@test "set a prerelease w/prefix and date and git (jenkins) build" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset BUILD_NUMBER
}

@test "set a prerelease w/prefix and date and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset TRAVIS_BUILD_NUMBER
}

@test "set a prerelease w/prefix and date and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset CIRCLE_BUILD_NUM
}

@test "set a prerelease w/prefix and date and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.abc.1}" <<< "$output"
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "increment prerelease multiple times w/ prefix" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.1" ]
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.2" ]
}
