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
    [ "$output" == "0.0.2" ]
}

@test "show a plain version" {
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "show a build version (git only in build component)" {
    run avakas_wrapper show "$REPO" --build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}" ]
}

@test "show a (jenkins) build version (git only + build number in build component)" {
    export BUILD_NUMBER=1
    run avakas_wrapper show "$REPO" --build
    unset BUILD_NUMBER
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}.1" ]
}

@test "show a (travis) build version (git only + build number in build component)" {
    export TRAVIS_BUILD_NUMBER=1
    run avakas_wrapper show "$REPO" --build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "show a build version (git only in build component with preexisting build component)" {
    template_skeleton "$REPO" plain "0.0.1+1"
    run avakas_wrapper show "$REPO" --build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1+1."$REV ]
}

@test "show a build version (git only in prerelease component)" {
    run avakas_wrapper show "$REPO" --pre-build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-${REV}" ]
}

@test "show a build version (git only in prerelease component with preexisting prerelease component)" {
    template_skeleton "$REPO" plain 0.0.1-1
    run avakas_wrapper show "$REPO" --pre-build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO)
    [ "$output" == "0.0.1-1."$REV ]
}

@test "show a (jenkins) build version (git only + build number in prerelease component)" {
    export BUILD_NUMBER=1
    run avakas_wrapper show "$REPO" --pre-build
    unset BUILD_NUMBER
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO_ORIGIN)
    [ "$output" == "0.0.1-${REV}.1" ]
}

@test "show a (travis) build version (git only + build number in prerelease component)" {
    export TRAVIS_BUILD_NUMBER=1
    run avakas_wrapper show "$REPO" --pre-build
    [ "$status" -eq 0 ]
    REV=$(current_rev $REPO_ORIGIN)
    [ "$output" == "0.0.1-${REV}.1" ]
    unset TRAVIS_BUILD_NUMBER
}

@test "bump a plain version - patch to patch" {
    run avakas_wrapper bump "$REPO" patch
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.2" ]
}

@test "bump a plain version - patch to minor" {
    run avakas_wrapper bump "$REPO" minor
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.1.0" ]
}

@test "bump a plain version - patch to major" {
    run avakas_wrapper bump "$REPO" major
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "1.0.0" ]
}

@test "bump because of git commit containing word major" {
    commit_to_repo "$REPO" "major"
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "1.0.0" ]
}

@test "bump because of git commit containing word minor" {
    commit_to_repo "$REPO" "minor"
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.1.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.1.0" ]
}

@test "bump because of git commit containing word patch" {
    commit_to_repo "$REPO" "patch"
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.0.2"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.2" ]
}

@test "multibump because of git commit containing words major and minor and patch" {
    commit_to_repo "$REPO" "major"
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "1.0.0" ]
}

@test "multibump because of git commit containing words major and minor" {
    commit_to_repo "$REPO" "major"
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "1.0.0" ]
}

@test "multibump because of git commit containing words major and patch" {
    commit_to_repo "$REPO" "major"
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 1.0.0"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "1.0.0" ]
}

@test "multibump because of git commit containing words minor and patch" {
    commit_to_repo "$REPO" 'minor'
    run avakas_wrapper bump "$REPO" auto
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.1.0" ]
}

@test "return problem because of git commit not containing words major, minor, or patch" {
    commit_to_repo "$REPO" "commit message with no special words"
    run "$AVAKAS" bump "$REPO" auto
    [ "$status" -eq 1 ]
    scan_lines "Problem: Invalid version component" "${lines[@]}"
    run "$AVAKAS" show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "return problem because of git commit containing similar looking words to test wildcard characters" {
    commit_to_repo "$REPO" "test for similar looking words like amjority"
    run "$AVAKAS" bump "$REPO" auto
    [ "$status" -eq 1 ]
    scan_lines "Problem: Invalid version component"  "${lines[@]}"
    run "$AVAKAS" show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "return problem because of git commit containing similar looking words to test wildcard characters" {
    commit_to_repo "$REPO" "test for similar looking words like aminority"
    run "$AVAKAS" bump "$REPO" auto
    [ "$status" -eq 1 ]
    scan_lines "Problem: Invalid version component"  "${lines[@]}"
    run "$AVAKAS" show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "return problem because of git commit containing similar looking words to test wildcard characters" {
    commit_to_repo "$REPO" "test for similar looking words like ampatching"
    run "$AVAKAS" bump "$REPO" auto
    [ "$status" -eq 1 ]
    scan_lines "Problem: Invalid version component"  "${lines[@]}"
    run "$AVAKAS" show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "bump a plain version - patch to prerelease" {
    run avakas_wrapper bump "$REPO" pre
    [ "$status" -eq 0 ]
    scan_lines "Version updated from 0.0.1 to 0.0.1-1"  "${lines[@]}"
    run avakas_wrapper show "$REPO"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1-1" ]

}

@test "show a plain version - specified filename" {
    plain_version "$REPO" "0.0.1-1" "foo"
    run avakas_wrapper show "$REPO" --filename "foo"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1-1" ]
}

@test "set a plain version - specified filename" {
    plain_version "$REPO" "0.0.1-1" "foo"
    run avakas_wrapper set "$REPO" "0.0.2" --filename "foo"
    [ "$status" -eq 0 ]
    run avakas_wrapper show "$REPO" --filename "foo"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.2" ]
}

@test "bump a plain version - patch->patch, specified filename" {
    plain_version "$REPO" "0.0.2" "foo"
    run avakas_wrapper bump "$REPO" "patch" --filename "foo"
    [ "$status" -eq 0 ]
    run avakas_wrapper show "$REPO" --filename "foo"
    [ "$status" -eq 0 ]
    [ "$output" == "0.0.3" ]
}
