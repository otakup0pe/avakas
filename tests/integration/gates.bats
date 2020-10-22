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

@test "untracked files are dirty" {
    cd "$REPO"
    touch aaaa
    git add aaaa
    avakas_rc 1 set "$REPO" "0.0.2"
    scan_lines "Problem: Git repo dirty." "${lines[@]}"
}

@test "skip checking for dirty files" {
    cd "$REPO"
    touch aaaa
    git add aaaa
    avakas_rc 0 set "$REPO" "0.0.2" --skip-dirty
    scan_lines "Version set to 0.0.2" "${lines[@]}"
}

@test "version file is being tracked" {
    cd "$REPO"
    avakas_rc 0 set "$REPO" "0.0.3" --filename tracked_version
    scan_lines "Version set to 0.0.3" "${lines[@]}"
    test $(git ls-files --error-unmatch tracked_version)
}

@test "skip committing version file" {
    cd "$REPO"
    avakas_rc 0 set "$REPO" "0.0.4" --filename da_testfile --skip-commit-change
    scan_lines "Version set to 0.0.4" "${lines[@]}"
    test ! $(git ls-files --error-unmatch da_testfile)
}
