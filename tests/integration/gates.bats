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

