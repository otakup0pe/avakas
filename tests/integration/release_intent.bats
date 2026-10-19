#!/usr/bin/env bats
# -*- mode: Shell-script;bash -*-

load helper

setup() {
    shared_setup
    REPO_ORIGIN=$(fake_repo)
    template_skeleton "$REPO_ORIGIN" plain "0.0.1"
    origin_repo "$REPO_ORIGIN"
    REPO=$(clone_repo "$REPO_ORIGIN")
}

teardown() {
    shared_teardown
}

@test "legacy accepts a spaced bump marker" {
    commit_message "$REPO" "Explicit release marker\nbump: patch"
    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "git-tag accepts a spaced bump marker" {
    commit_message "$REPO" "Explicit release marker\nbump: patch"
    avakas_wrapper bump "$REPO" auto --flavor git-tag
    avakas_wrapper show "$REPO" --flavor git-tag
    [ "$output" == "0.0.2" ]
}

@test "legacy finds a marker merged from a feature branch" {
    cd "$REPO"
    git checkout -qb feature
    echo feature > feature-file
    git add feature-file
    git commit -qm $'Feature work\nbump:patch'
    git checkout -q mainline
    echo mainline > mainline-file
    git add mainline-file
    git commit -qm "Mainline work"
    git merge -q --no-ff feature -m "Merge feature"

    avakas_wrapper bump "$REPO" auto
    avakas_wrapper show "$REPO"
    [ "$output" == "0.0.2" ]
}

@test "git-tag finds a marker merged from a feature branch" {
    cd "$REPO"
    git checkout -qb feature
    echo feature > feature-file
    git add feature-file
    git commit -qm $'Feature work\nbump:patch'
    git checkout -q mainline
    echo mainline > mainline-file
    git add mainline-file
    git commit -qm "Mainline work"
    git merge -q --no-ff feature -m "Merge feature"

    avakas_wrapper bump "$REPO" auto --flavor git-tag
    avakas_wrapper show "$REPO" --flavor git-tag
    [ "$output" == "0.0.2" ]
}

@test "git-tag allocates prereleases across branches and multiple digits" {
    cd "$REPO"
    git checkout -qb prereleases
    echo prereleases > prerelease-file
    git add prerelease-file
    git commit -qm "Prerelease tags"

    local number
    for number in {1..11}; do
        git tag "0.0.2-beta.${number}"
    done
    git tag "0.0.2-alpha.99"
    git tag "0.0.3-beta.99"
    git checkout -q mainline

    avakas_wrapper bump "$REPO" patch \
        --prerelease --prerelease-prefix beta --flavor git-tag
    avakas_wrapper show "$REPO" --flavor git-tag
    [ "$output" == "0.0.2-beta.12" ]
}

@test "legacy rejects an unchanged explicit version without mutation" {
    local before
    before=$(git -C "$REPO" rev-parse HEAD)

    avakas_rc 1 set "$REPO" "0.0.1"
    scan_lines "Attempted to set the version to its previous value" "${lines[@]}"
    [ "$before" == "$(git -C "$REPO" rev-parse HEAD)" ]
}

@test "git-tag rejects an unchanged explicit version without mutation" {
    local before
    before=$(git -C "$REPO" rev-parse HEAD)

    avakas_rc 1 set "$REPO" "0.0.1" --flavor git-tag
    scan_lines "Attempted to set the version to its previous value" "${lines[@]}"
    [ "$before" == "$(git -C "$REPO" rev-parse HEAD)" ]
    [ "$(git -C "$REPO" tag --list 0.0.1 | wc -l)" -eq 1 ]
}
