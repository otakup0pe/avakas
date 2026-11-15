#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" erlang "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo $REPO_ORIGIN)
}

teardown() {
    shared_teardown
}

@test "show an erlang version" {
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.1" ]
}

@test "show an erlang version with explicit flavor" {
    avakas_wrapper show "$REPO" --flavor erlang
    [ "$output" == "0.0.1" ]
}

@test "set an erlang version" {
    avakas_wrapper set "$REPO" "0.0.2"
    scan_lines "Version set to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "reject an unchanged erlang version without mutation" {
    local before
    before=$(git -C "$REPO" rev-parse HEAD)

    avakas_rc 1 set "$REPO" "0.0.1"
    scan_lines "Attempted to set the version to its previous value" "${lines[@]}"
    [ "$before" == "$(git -C "$REPO" rev-parse HEAD)" ]
    git -C "$REPO" diff --quiet
}

@test "bump an erlang version - patch" {
    avakas_wrapper bump "$REPO" patch
    scan_lines "Version updated from 0.0.1 to 0.0.2" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "bump an erlang version - minor" {
    avakas_wrapper bump "$REPO" minor
    scan_lines "Version updated from 0.0.1 to 0.1.0" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "0.1.0" ]
}

@test "bump an erlang version - major" {
    avakas_wrapper bump "$REPO" major
    scan_lines "Version updated from 0.0.1 to 1.0.0" "${lines[@]}"
    avakas_wrapper show "$REPO"
    [ "$output" == "1.0.0" ]
}

@test "a bump rewrites only the live vsn tuple" {
    avakas_wrapper bump "$REPO" patch
    local APP_SRC="${REPO}/src/test_project.app.src"

    grep -qF '{vsn, "0.0.2"}' "$APP_SRC"
    grep -qF '%% {vsn, "0.0.0"} was here before avakas owned it' "$APP_SRC"
    grep -qF '{description, "Test project"}' "$APP_SRC"
}

@test "a bump commits and tags the application file" {
    avakas_wrapper bump "$REPO" patch

    [ "$(git -C "$REPO" log -1 --format=%s)" == "Version bumped to 0.0.2" ]
    git -C "$REPO" diff --quiet
    git -C "$REPO" rev-parse --verify "refs/tags/0.0.2"
    git -C "$REPO" log -1 --format=%s origin/mainline | grep -qF "Version bumped to 0.0.2"
}
