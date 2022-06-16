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

@test "bump a prerelease prefix" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1" ]
}

@test "bump a prerelease w/prefix and git build" {
  REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}" ]
}

@test "bump a prerelease w/prefix and git (jenkins) build" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.1" ]
    unset BUILD_NUMBER
}

@test "bump a prerelease w/prefix and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "bump a prerelease w/prefix and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.1" ]
    unset CIRCLE_BUILD_NUM
}

@test "bump a prerelease w/prefix and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix=alpha --build
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-alpha.1+${REV}.abcd.1" ]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "bump a prerelease w/date" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    # Verify the 'bump' output
    [[ "$output" =~ ^Version.*updated.*0\.0\.0.*0\.0\.1-1\.${ALMOST} ]]
    
    # Verify the set version
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-1.${ALMOST}[0-9]{2}$ ]]

}

@test "set a prerelease w/date" {
    avakas_wrapper set "$REPO" 1.2.3 --prerelease --prerelease-date
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    avakas_wrapper show "$REPO"

    # Will only show on errors
    echo "'${output}' does not match the expected '^1.2.3\-1.${ALMOST}[0-9]{2}$'"
    [[ "$output" =~ ^1.2.3\-1.${ALMOST}[0-9]{2}$ ]]    
}

@test "bump a prerelease w/date and git build" {
  REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease  --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"

    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-1.${ALMOST}[0-9]{2}\+${REV}$ ]]
}

@test "bump a prerelease w/date and git (jenkins) build" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-1.${ALMOST}[0-9]{2}\+${REV}\.1$ ]]

    unset BUILD_NUMBER
}

@test "bump a prerelease w/date and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-1.${ALMOST}[0-9]{2}\+${REV}\.${TRAVIS_BUILD_NUMBER}$ ]]

    unset TRAVIS_BUILD_NUMBER
}

@test "bump a prerelease w/date and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
   
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-1.${ALMOST}[0-9]{2}\+${REV}\.${CIRCLE_BUILD_NUM}$ ]]

    unset CIRCLE_BUILD_NUM
}

@test "bump a prerelease w/date and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-1.${ALMOST}[0-9]{2}\+${REV}\.${GITHUB_RUN_ID}\.${GITHUB_RUN_NUMBER}$ ]]

    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "bump a prerelease w/prefix and date" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-alpha.1.${ALMOST}[0-9]{2}$ ]]
}

@test "bump a prerelease w/prefix and date and git build" {
  REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"

    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-alpha.1.${ALMOST}[0-9]{2}\+${REV}$ ]]
}

@test "bump a prerelease w/prefix and date and git (jenkins) build" {
    export BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-alpha.1.${ALMOST}[0-9]{2}\+${REV}\.${BUILD_NUMBER}$ ]]
    
    unset BUILD_NUMBER
}

@test "bump a prerelease w/prefix and date and git (travis) build" {
    export TRAVIS_BUILD_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
   
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-alpha.1.${ALMOST}[0-9]{2}\+${REV}\.1$ ]]
    
    unset TRAVIS_BUILD_NUMBER
}

@test "bump a prerelease w/prefix and date and git (circle) build" {
    export CIRCLE_BUILD_NUM=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
   
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-alpha.1.${ALMOST}[0-9]{2}\+${REV}\.${CIRCLE_BUILD_NUM}$ ]]
    
    unset CIRCLE_BUILD_NUM
}

@test "bump a prerelease w/prefix and date and git (gha) build" {
    export GITHUB_RUN_ID=abcd
    export GITHUB_RUN_NUMBER=1
    REV=$(current_rev $REPO)
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-date --prerelease-prefix=alpha --build
    ALMOST="$(TZ='UTC' date "+%Y%m%d%H%M")"
    
    avakas_wrapper show "$REPO"
    [[ "$output" =~  ^0.0.1-alpha.1.${ALMOST}[0-9]{2}\+${REV}\.${GITHUB_RUN_ID}\.${GITHUB_RUN_NUMBER}$ ]]
    unset GITHUB_RUN_ID
    unset GITHUB_RUN_NUMBER
}

@test "minimal increment prerelease multiple times w/ prefix" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.1" ]
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.2" ]
}


@test "increment prerelease multiple times w/ prefix, changing prefix" {
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.1" ]
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.2" ]
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix beta
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-beta.3" ]
    avakas_wrapper bump "$REPO" patch --prerelease --prerelease-prefix rc
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1-rc.1" ]
}
