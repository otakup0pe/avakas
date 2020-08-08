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

@test "show a prerelease prefix" {
    avakas_wrapper show "$REPO" --pre-build --pre-build-prefix=alpha
    [ "$output" == "0.0.1-alpha" ]
}

@test "show a prerelease w/prefix and git build" {
    avakas_wrapper show "$REPO" --pre-build --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-alpha+${REV}" ]
}

@test "show a prerelease w/prefix and git (jenkins) build" {
    export BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-alpha+${REV}.1" ]
    unset BUILD_NUMBER
}

@test "show a prerelease w/prefix and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-alpha+${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "show a prerelease w/prefix and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-alpha+${REV}.1" ]
    unset CIRCLE_BUILD_NUM
}

@test "show a prerelease w/prefix and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-alpha+${REV}.abcd.1" ]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "show a prerelease w/date" {
    avakas_wrapper show "$REPO" --pre-build --pre-build-date
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    MATCH="$(rev <<< "$output" | cut -c 3- | rev)"
    [ "$MATCH" == "0.0.1-${ALMOST}" ]
}

@test "show a prerelease w/date and git build" {
    avakas_wrapper show "$REPO" --pre-build  --pre-build-date --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}" <<< "$output"
}

@test "show a prerelease w/date and git (jenkins) build" {
    export BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset BUILD_NUMBER
}

@test "show a prerelease w/date and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset TRAVIS_BUILD_NUMBER
}

@test "show a prerelease w/date and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset CIRCLE_BUILD_NUM
}

@test "show a prerelease w/date and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-${ALMOST}[0-9]{2}\+${REV}.abc.1}" <<< "$output"
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "show a prerelease w/prefix and date" {
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --pre-build-prefix=alpha
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1-alpha.${ALMOST}[0-9]{2}" <<< "$output"
}

@test "show a prerelease w/prefix and date and git build" {
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}" <<< "$output"
}

@test "show a prerelease w/prefix and date and git (jenkins) build" {
    export BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset BUILD_NUMBER
}

@test "show a prerelease w/prefix and date and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset TRAVIS_BUILD_NUMBER
}

@test "show a prerelease w/prefix and date and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.1" <<< "$output"
    unset CIRCLE_BUILD_NUM
}

@test "show a prerelease w/prefix and date and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    avakas_wrapper show "$REPO" --pre-build --pre-build-date --pre-build-prefix=alpha --build
    REV=$(current_rev $REPO)
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    grep -v "0.0.1\-alpha.${ALMOST}[0-9]{2}\+${REV}.abc.1}" <<< "$output"
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}
